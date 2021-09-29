--DATA CLEANING--

--view the data
SELECT*
FROM HousingData.dbo.Housing;


------------------------- CONVERT DATE FORMAT-------------------------

--check the saleDate format
SELECT SaleDate
FROM HousingData.dbo.Housing;

--SaleDate is in DateTime format. Convert it to date.
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM HousingData.dbo.Housing;

--Add a new SaleDates column
ALTER TABLE HousingData.dbo.Housing
ADD SaleDates Date;

--update and populate the column
UPDATE HousingData.dbo.Housing
SET SaleDates = CONVERT(Date, SaleDate);


--------------POPULATE THE NULLS IN PROPERTY ADDRESS COLUMN---------------
SELECT*
FROM HousingData.dbo.Housing
WHERE PropertyAddress is NULL;


--ParcelID matches the PropertyAddress
--use self joins to populate the property address column

SELECT a.ParcelID, a.PropertyAddress,b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM HousingData.dbo.Housing a
JOIN HousingData.dbo.Housing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is NULL;


--update the table
--when updating tables with joins, use aliases.

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM HousingData.dbo.Housing a
JOIN HousingData.dbo.Housing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is NULL;

----------------SPLIT THE PROPERTY ADDRESS COLUMN---------------------

-- split the property address into address, city and state.
--Note the comma delimiter
SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX (',', PropertyAddress)-1),
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))
FROM HousingData.dbo.Housing;

--Create the two new columns 
--Address column
ALTER TABLE HousingData.dbo.Housing
ADD Address Nvarchar(255);

UPDATE HousingData.dbo.Housing
SET Address = SUBSTRING(PropertyAddress, 1, CHARINDEX (',', PropertyAddress)-1);

--city column
ALTER TABLE HousingData.dbo.Housing
ADD City Nvarchar(255);

UPDATE HousingData.dbo.Housing
SET City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))


-------------------SPLIT OWNER ADDRESS-------------------------------
SELECT OwnerAddress
FROM HousingData.dbo.Housing;

--Use PARSENAME. It works with periods hence we replace the commas with periods.
--PARSENAME works backwards hence we start from 3,2,1 . 
SELECT
PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM HousingData.dbo.Housing;

--create the three new columns and  update them
ALTER TABLE HousingData.dbo.Housing
ADD AddressOwner Nvarchar(255);

UPDATE HousingData.dbo.Housing
SET AddressOwner = PARSENAME(REPLACE(OwnerAddress,',','.'),3);

ALTER TABLE HousingData.dbo.Housing
ADD CityOwner Nvarchar(255); 

UPDATE HousingData.dbo.Housing
SET CityOwner = PARSENAME(REPLACE(OwnerAddress,',','.'),2);

ALTER TABLE HousingData.dbo.Housing
ADD StateOwner Nvarchar(255); 

UPDATE HousingData.dbo.Housing
SET StateOwner = PARSENAME(REPLACE(OwnerAddress,',','.'),1);


---------------------CONSISTENCY OF WORDS-----------------------

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM HousingData.dbo.Housing
GROUP BY SoldAsVacant
ORDER BY 2 DESC;

-- replace Y and N with YES and NO using CASE

SELECT SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From HousingData.dbo.Housing;


--Update table
UPDATE Housing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' Then 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant
END;



-----------------REMOVE DEPLICATES-------------------------
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
			     PropertyAddress,
				 Saleprice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
				 UniqueID
				 ) row_num
FROM HousingData.dbo.Housing
)
DELETE 
FROM RowNumCTE
WHERE row_num >1;


-------------DELETE UNUSED COLUMNS---------------

ALTER TABLE HousingData.dbo.Housing
DROP COLUMN OwnerAddress,TaxDistrict,PropertyAddress;