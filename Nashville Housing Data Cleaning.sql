--Cleaning Data in SQL Queries

SELECT *
FROM Nashville_Housing..Nashville_Housing

--------------------------------------------------------------------------------------------------------------------

--Standardize Date Format (Creating new column to store converted date values)
ALTER TABLE Nashville_Housing..Nashville_Housing
ADD ConvertedSaleDate DATE

UPDATE Nashville_Housing..Nashville_Housing
SET ConvertedSaleDate = CAST(SaleDate as DATE)

--------------------------------------------------------------------------------------------------------------------

--Populate Property Address Data (populated based on matched ParcelIDs)
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Nashville_Housing..Nashville_Housing a
JOIN Nashville_Housing..Nashville_Housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Nashville_Housing..Nashville_Housing a
JOIN Nashville_Housing..Nashville_Housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

--------------------------------------------------------------------------------------------------------------------

--Breaking out Address into New Individual Columns (Address, City, State)

--Creating separate columns for Property Address (technique 1)
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) as Address
FROM Nashville_Housing..Nashville_Housing

ALTER TABLE Nashville_Housing..Nashville_Housing
ADD PropertySplitAddress Nvarchar(255)

UPDATE Nashville_Housing..Nashville_Housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE Nashville_Housing..Nashville_Housing
ADD PropertySplitCity Nvarchar(255)

UPDATE Nashville_Housing..Nashville_Housing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))


--Creating separate columns for Owner Address (technique 2)
SELECT
PARSENAME(REPLACE(OwnerAddress,',','.'), 3) as Address
, PARSENAME(REPLACE(OwnerAddress,',','.'), 2) as City
, PARSENAME(REPLACE(OwnerAddress,',','.'), 1) as State
FROM Nashville_Housing..Nashville_Housing

ALTER TABLE Nashville_Housing..Nashville_Housing
ADD OwnerSplitAddress Nvarchar(255)

UPDATE Nashville_Housing..Nashville_Housing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'), 3)

ALTER TABLE Nashville_Housing..Nashville_Housing
ADD OwnerSplitCity Nvarchar(255)

UPDATE Nashville_Housing..Nashville_Housing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'), 2)

ALTER TABLE Nashville_Housing..Nashville_Housing
ADD OwnerSplitState Nvarchar(255)

UPDATE Nashville_Housing..Nashville_Housing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'), 1)

--------------------------------------------------------------------------------------------------------------------

--Change Y and N to Yes and No in "Sold as Vacant" field
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM Nashville_Housing..Nashville_Housing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM Nashville_Housing..Nashville_Housing

UPDATE Nashville_Housing..Nashville_Housing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END

--------------------------------------------------------------------------------------------------------------------

--Remove Duplicates

WITH CTE AS (
	SELECT *,
		ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
		ORDER BY (SELECT NULL)) AS RN
	FROM Nashville_Housing..Nashville_Housing
)
DELETE FROM CTE WHERE RN > 1
	
--------------------------------------------------------------------------------------------------------------------

--Deleting Unused Columns
ALTER TABLE Nashville_Housing..Nashville_Housing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict

ALTER TABLE Nashville_Housing..Nashville_Housing
DROP COLUMN SaleDate