---CREATE TABLE
CREATE TABLE Customer
(
	CustomerID int not null,
	UserName nvarchar(40) not null,
	[Password] varchar(30) NOT NULL,
	[Address] varchar(50),
	Phone# varchar(15),
CONSTRAINT Customer_PK primary key (CustomerID )
);


CREATE TABLE VIPCustomer
(
	CustomerID int not null,
	DiscountRate varchar(10),
	DeliveryCoupon float,
CONSTRAINT VIPCustomer_PK PRIMARY KEY (CustomerID),
CONSTRAINT VIPCustomer_FK foreign key (CustomerID ) references Customer(CustomerID),
CONSTRAINT Check_Coupon CHECK (DeliveryCoupon BETWEEN 1 and 10)  
);


CREATE TABLE FrequentCustomer
(
	CustomerID int not null,
	Order#perMonth int,
CONSTRAINT FrequentCustomer_PK PRIMARY KEY (CustomerID),
CONSTRAINT FrequentCustomer_FK foreign key (CustomerID ) references Customer(CustomerID)
);

create table CustomerService
( 
	ServerID int not null,
	ServerName nvarchar(40),
CONSTRAINT Server_PK primary key (ServerID )
);


create table Restaurant
(
	RestaurantID int not null,
	RestaurantName nvarchar(40) not null,
	[Address] varchar(50),
	Phone# varchar(15),
	OpenTime time,
	CloseTime time,
	RestaurantCategories varchar(90),
CONSTRAINT Restaurant_PK PRIMARY KEY (RestaurantID)	
);

CREATE TABLE Item
(
	ItemID int not null,
	RestaurantID int,
	ItemName varchar(40),
	ItemDescription varchar(100),
	ItemCategory varchar(20),
	ItemUnitPrice float,
CONSTRAINT Item_PK PRIMARY KEY (ItemID),
CONSTRAINT Item_FK FOREIGN KEY (RestaurantID) REFERENCES Restaurant (RestaurantID),
CONSTRAINT Check_Price CHECK (ItemUnitPrice >0)
);

CREATE TABLE [Order]
(
	OrderID int not null,
	CustomerID int not null,
	RestaurantID int not null,
	OrderTime datetime default (getdate()),
CONSTRAINT Order_PK PRIMARY KEY (OrderID),
CONSTRAINT Order_FK1 FOREIGN KEY (CustomerID) REFERENCES Customer (CustomerID),
CONSTRAINT Order_FK2 FOREIGN KEY (RestaurantID) REFERENCES Restaurant (RestaurantID)
);

CREATE TABLE OrderLine
(
	OrderlineID int not null,
	OrderID int not null,
	ItemID int not null,
	OrderedQuantity int,
CONSTRAINT OrderLine_PK PRIMARY KEY (OrderlineID),
CONSTRAINT OrderLine_FK1 FOREIGN KEY (OrderID) REFERENCES [Order] (OrderID),
CONSTRAINT OrderLine_FK2 FOREIGN KEY (ItemID) REFERENCES Item (ItemID)
);

CREATE TABLE DeliveryDriver
(
	DriverID int not null,
	DriverName nvarchar(40) not null,
	Phone# varchar(15),
	CarType varchar(20),
	VIN varchar(40),
CONSTRAINT DeliveryDriver_PK PRIMARY KEY (DriverID)
);

CREATE TABLE Delivery
(
	OrderID int not null,
	DriverID int not null,
	DeliveryFee float,
	DeliveryTime datetime default (getdate()),
CONSTRAINT Delivery_PK PRIMARY KEY (OrderID, DriverID),
CONSTRAINT Delivery_FK1 FOREIGN KEY (OrderID) REFERENCES [Order] (OrderID),
CONSTRAINT Delivery_FK2 FOREIGN KEY (DriverID) REFERENCES [DeliveryDriver] (DriverID)
);

CREATE TABLE [Transaction]
(
	TransactionID int not null,
	OrderID int ,
	PaymentMethod varchar(20),
	
CONSTRAINT Transaction_PK PRIMARY KEY (TransactionID),
CONSTRAINT Transaction_FK FOREIGN KEY (OrderID) REFERENCES [Order] (OrderID),
CONSTRAINT Check_method CHECK (PaymentMethod in ('Credit Card','Debit Card','PayPal'))
);

CREATE TABLE Feedback
(
	FeedbackID int not null,
	RestaurantID int not null,
	CustomerID int not null,
	Rating decimal(2,1),
	Comment varchar(200),
CONSTRAINT Feedback_PK PRIMARY KEY (FeedbackID),
CONSTRAINT Feedback_FK1 FOREIGN KEY (RestaurantID) REFERENCES Restaurant (RestaurantID),
CONSTRAINT Feedback_FK2 FOREIGN KEY (CustomerID) REFERENCES Customer (CustomerID)
);


---CREATE PROCEDURE

GO
CREATE PROCEDURE AssignDelivery (@OrderID int,@DriverID int,@DeliveryFee float)
as 
begin
INSERT INTO Delivery values(@OrderID,@DriverID,@DeliveryFee,getdate());

SELECT C.CustomerID,C.UserName,C.[Address],C.Phone#,
R.RestaurantID,R.RestaurantName,R.[Address],R.Phone#
FROM [Order] O join Customer C on O.CustomerID = C.CustomerID
			   join Restaurant R on O.RestaurantID=R.RestaurantID
WHERE OrderID = @OrderID

END;

---exec AssignDelivery 18,5,2.99;

Go 
CREATE PROCEDURE SearchFood(@ItemDescription varchar(100),@ItemCategory varchar(20))
as 
begin
SELECT ItemID,ItemName,ItemDescription,ItemCategory
FROM Item
WHERE ItemDescription like '%'+@ItemDescription+'%' or ItemCategory = @ItemCategory
end;

---exec SearchFood 'Chicken' ,'Sandwich'

GO 
CREATE PROCEDURE RestaurantRating 
as
begin
select r.RestaurantName, AVG(f.rating) as Rating
from Restaurant r left join Feedback f on r.RestaurantID=f.RestaurantID
group by r.RestaurantName
end;

---exec RestaurantRating


GO
CREATE PROCEDURE DriverFee (@DriverID INT,@DriverName nvarchar(40))
as
begin
	select DriverName ,sum(d.DeliveryFee) as TotalDeliveryFee
	FROM DeliveryDriver dd left join Delivery d on dd.DriverID=d.DriverID
	where dd.DriverID=@DriverID or dd.DriverName = @DriverName
	group by dd.DriverName
end;

---exec DriverFee 2,'';


Go 
CREATE PROCEDURE SearchRestaurant(@RestaurantName nvarchar(40),@RestaurantCategories varchar(90))
as 
begin
SELECT RestaurantID,RestaurantName,RestaurantCategories
FROM Restaurant
WHERE RestaurantName = @RestaurantName OR RestaurantCategories like '%'+@RestaurantCategories+'%' 
end;

---exec SearchRestaurant 'Blunch' ,'Chinese'

GO
CREATE PROCEDURE SelectCustomer @UserName nvarchar(40)
AS
BEGIN  
	SELECT CustomerID, UserName, [Address], Phone#
	from Customer
	where UserName=@UserName 
END

Exec SelectCustomer 'Carolee'



---CREATE FUNCTION
GO
CREATE FUNCTION GetFrequentCustomer(@orderpermonth INT)
RETURNS @FrequentCustomer TABLE ( CustomerName VARCHAR(10), Order#perMonth int)
AS
BEGIN
INSERT INTO @FrequentCustomer
select UserName,Order#perMonth from Customer c join FrequentCustomer f ON c.customerid=f.customerid where f.Order#perMonth>@orderpermonth
RETURN

END 

---select * from GetFrequentCustomer(10)

GO
CREATE FUNCTION GetRestaurantRating()
RETURNS @RestaurantRating TABLE ( RestaurantName nvarchar(60),Rating Numeric(6,2))
AS
BEGIN
INSERT INTO @RestaurantRating
select r.RestaurantName , Avg(f.Rating ) AS Rating from Restaurant r inner join Feedback f ON r.RestaurantID = f.RestaurantID  
group by r.RestaurantName
RETURN
END 

---select * from GetRestaurantRating()

GO
CREATE FUNCTION F_SearchFood(@ItemDescription varchar(100),@ItemCategory varchar(20))
RETURNS @SearchFood TABLE ( 
ItemID int,ItemName  nvarchar(60),ItemDescription  nvarchar(100),ItemCategory  nvarchar(60))
AS
BEGIN
INSERT INTO @SearchFood

SELECT ItemID,ItemName,ItemDescription,ItemCategory
FROM Item
WHERE ItemDescription like '%'+@ItemDescription+'%' or ItemCategory = @ItemCategory
RETURN
END 

---select * from F_SearchFood('Chicken','Sandwich')

GO
CREATE FUNCTION ShowCustomerDetails(@UserName nvarchar(40))
RETURNS @ShowCustomerDetails TABLE ( 
CustomerID int, UserName  nvarchar(60), [Address]  nvarchar(100), Phone# nvarchar(20) )
AS
BEGIN
INSERT INTO @ShowCustomerDetails
	SELECT CustomerID, UserName, [Address], Phone#
	from Customer
	where UserName=@UserName 
RETURN
END 

---select * from ShowCustomerDetails('Thea')


--CREATE TRIGGER
CREATE TABLE RestaurantAudit(
	RestaurantAuditID int primary key identity(1,1),
	RestaurantID int not null,
	RestaurantName nvarchar(40) not null,
	[Address] varchar(50),
	Phone# varchar(15),
	OpenTime time,
	RestaurantCategories varchar(20),
	Action char(1),
	ActionDate datetime
);

GO
CREATE TRIGGER RestaurantChanges on Restaurant
FOR UPDATE
AS
BEGIN

	INSERT INTO RestaurantAudit (RestaurantID,RestaurantName,[Address],Phone#,
OpenTime,RestaurantCategories,[Action],	ActionDate) 
	SELECT d.RestaurantID,d.RestaurantName,d.[Address],d.Phone#,
d.OpenTime,d.RestaurantCategories,'U',GETDATE()
	FROM deleted d

END



---CREATE VIEW
GO
CREATE VIEW v_menu 
	as select r.RestaurantID,r.RestaurantName,RestaurantCategories,OpenTime,CloseTime,
	ItemName,ItemDescription,ItemCategory,ItemUnitPrice
	from Restaurant r join Item i on r.RestaurantID=i.RestaurantID
	
---select *from v_menu

GO
CREATE VIEW V_rating
	as select RestaurantName,AVG(Rating) as AveRating
	from Feedback f join Restaurant r on f.RestaurantID=r.RestaurantID
	group by RestaurantName

---select * from V_rating

GO
CREATE VIEW V_CustomerInfo
	as select CustomerID,UserName,[Address],Phone#,EncryptedPassword
	from Customer

---select * from V_CustomerInfo

GO
CREATE VIEW V_Feedback
	as select RestaurantName, Comment
	from Restaurant r left join Feedback f on r.RestaurantID = f.RestaurantID

---select * from V_Feedback


---CREATE ENCRYPTION COLUMN
GO
CREATE MASTER KEY ENCRYPTION BY
PASSWORD = 'INFO 6210';

GO
CREATE CERTIFICATE Customer007
	WITH SUBJECT = 'Customer Password';

GO
CREATE SYMMETRIC KEY Password_key_01
	WITH ALGORITHM = AES_256
	ENCRYPTION BY CERTIFICATE Customer007;

ALTER TABLE Customer ADD EncryptedPassword varbinary(128);

GO
OPEN SYMMETRIC KEY Password_key_01
	DECRYPTION BY CERTIFICATE Customer007;

UPDATE Customer
SET EncryptedPassword = ENCRYPTBYKEY(key_GUID('Password_key_01'), Password);


ALTER TABLE Customer DROP COLUMN [Password]
---select*from Customer

---CREATE NONCLUSTERED INDEX
CREATE NONCLUSTERED INDEX U_Name ON Customer (UserName) with FILLFACTOR = 60;
Sp_helpindex Customer

CREATE NONCLUSTERED INDEX D_Name ON DeliveryDriver (DriverName) with FILLFACTOR = 60;
CREATE NONCLUSTERED INDEX I_Name ON Item (ItemName) with FILLFACTOR = 60;
CREATE NONCLUSTERED INDEX R_Name ON Restaurant (RestaurantName) with FILLFACTOR = 60;
