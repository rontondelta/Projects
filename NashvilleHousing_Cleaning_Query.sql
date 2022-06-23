SELECT * 
FROM PortfolioProject..NashvilleHousing

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Standardize Sale Date

SELECT SaleDate, CONVERT(Date, SaleDate) as Updated
FROM PortfolioProject..NashvilleHousing;

ALTER TABLE PortfolioProject..NashvilleHousing
ADD SaleDateConverted Date;

--UPDATE PortfolioProject..NashvilleHousing
--SET SaleDateConverted = CONVERT(Date, SaleDate);

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN SaleDate;

EXEC sp_rename 'NashvilleHousing.SaleDateConverted', 'SaleDate', 'COLUMN';


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Populate Property Address data 
-- Check Parcel ID
-- If Parcel ID is same and Address is null then populate that with the same address

SELECT *
FROM PortfolioProject..NashvilleHousing
WHERE PropertyAddress is NULL
ORDER BY 2

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	on a.ParcelID = b.ParcelID -- Same Parcel ID
	AND a.[UniqueID ] <> b.[UniqueID ] -- Different Addresses (NULL and existing)
WHERE a.PropertyAddress is NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is NULL


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Breaking Address into Individual Columns (Address, City, State)
-- For Property's Address
SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing;

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as City
FROM PortfolioProject..NashvilleHousing;

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitCity Nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

-- For Owner's Address
SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing;

SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) -- PARSENAME Separates by '.' So we replace the comma. -- Output: Address
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) -- The columns are also formed in backwards order --Output: City
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) -- Hence, Indexes are in Descending order --Output: State
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255);

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitCity Nvarchar(255);

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitState Nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitState= PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Change Y and N => Yes and No in "Sold as Vacant" Column

SELECT Distinct(SoldAsVacant), Count(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT DISTINCT(SoldAsVacant),
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END as Updated_Values
FROM PortfolioProject..NashvilleHousing

UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END 


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remove Duplicates

WITH RowNumCTE AS(
SELECT *, 
	ROW_NUMBER() OVER ( 
	PARTITION BY ParcelID, 
				 PropertyAddress, 
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num
FROM PortfolioProject..NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

WITH RowNumCTE AS(
SELECT *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID, 
				 PropertyAddress, 
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num
FROM PortfolioProject..NashvilleHousing
-- ORDER BY ParcelID
)
DELETE
FROM RowNumCTE
WHERE row_num > 1


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remove Unused Columns

SELECT * 
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress

