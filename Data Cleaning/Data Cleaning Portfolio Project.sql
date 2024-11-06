/*
	Cleaning Data in SQL Queries
*/

SELECT *
FROM ProjectPortfolio..NashvilleHousing

-- Create staging table
SELECT *
INTO ProjectPortfolio..NashvilleHousingStaging
FROM ProjectPortfolio..NashvilleHousing

SELECT *
FROM ProjectPortfolio..NashvilleHousingStaging

-- Standardize Date Format
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM ProjectPortfolio..NashvilleHousingStaging

ALTER TABLE ProjectPortfolio..NashvilleHousingStaging
ADD SaleDateConverted Date;

UPDATE ProjectPortfolio..NashvilleHousingStaging
SET SaleDateConverted = CONVERT(Date, SaleDate)



-- Populate Property Address Data
SELECT *
FROM ProjectPortfolio..NashvilleHousingStaging
WHERE PropertyAddress IS NULL
ORDER BY ParcelID

SELECT t1.ParcelID, t1.PropertyAddress, t2.ParcelID, t2.PropertyAddress, ISNULL(t1.PropertyAddress, t2.PropertyAddress)
FROM ProjectPortfolio..NashvilleHousingStaging t1
JOIN ProjectPortfolio..NashvilleHousingStaging t2
	ON t1.ParcelID = t2.ParcelID
	AND t1.[UniqueID ] != t2.[UniqueID ]
WHERE t1.PropertyAddress IS NULL

UPDATE t1
SET PropertyAddress = ISNULL(t1.PropertyAddress, t2.PropertyAddress)
FROM ProjectPortfolio..NashvilleHousingStaging t1
JOIN ProjectPortfolio..NashvilleHousingStaging t2
	ON t1.ParcelID = t2.ParcelID
	AND t1.[UniqueID ] != t2.[UniqueID ]
WHERE t1.PropertyAddress IS NULL



-- Breaking out Address into individual columns (address, city, state)
SELECT PropertyAddress
FROM ProjectPortfolio..NashvilleHousingStaging

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS Address
FROM ProjectPortfolio..NashvilleHousingStaging

ALTER TABLE ProjectPortfolio..NashvilleHousingStaging
ADD PropertySplitAddress NVARCHAR(255)

UPDATE ProjectPortfolio..NashvilleHousingStaging
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE ProjectPortfolio..NashvilleHousingStaging
ADD PropertySplitCity NVARCHAR(255)

UPDATE ProjectPortfolio..NashvilleHousingStaging
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))



SELECT OwnerAddress
FROM ProjectPortfolio..NashvilleHousingStaging

SELECT 
PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM ProjectPortfolio..NashvilleHousingStaging

ALTER TABLE ProjectPortfolio..NashvilleHousingStaging
ADD OwnerSplitAddress NVARCHAR(255)

UPDATE ProjectPortfolio..NashvilleHousingStaging
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

ALTER TABLE ProjectPortfolio..NashvilleHousingStaging
ADD OwnerSplitCity NVARCHAR(255)

UPDATE ProjectPortfolio..NashvilleHousingStaging
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

ALTER TABLE ProjectPortfolio..NashvilleHousingStaging
ADD OwnerSplitState NVARCHAR(255)

UPDATE ProjectPortfolio..NashvilleHousingStaging
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)



-- Change Y and N to Yes and No in "Sold as Vacant" field
SELECT DISTINCT(SoldAsVacant), COUNT(SoldASVacant)
FROM ProjectPortfolio..NashvilleHousingStaging
GROUP BY SoldAsVacant
ORDER BY 2

UPDATE ProjectPortfolio..NashvilleHousingStaging
SET SoldAsVacant = 'Yes'
WHERE SoldAsVacant = 'Y'

UPDATE ProjectPortfolio..NashvilleHousingStaging
SET SoldAsVacant = 'No'
WHERE SoldAsVacant = 'N'



-- Remove Duplicates
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY 
					UniqueID
					) row_num
FROM ProjectPortfolio..NashvilleHousingStaging
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1



-- Delete Unused Columns
SELECT *
FROM ProjectPortfolio..NashvilleHousingStaging

ALTER TABLE ProjectPortfolio..NashvilleHousingStaging
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate
