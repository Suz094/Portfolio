/*

Cleaning Data in SQL Queries

*/




#-- ERRORS - Statements starting with # are errors or methods that didn't work in MYSQL Workbench 




USE portfolio_project;


SELECT * 
FROM portfolio_project.nashvillehousing;




--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format




#-- Convert and cast function did not work here



-- SELECT SaleDate, str_to_date(SaleDate, '%d-%M-%y'), SaleDateConverted
-- FROM portfolio_project.nashvillehousing;

-- ALTER TABLE nashvillehousing
-- ADD COLUMN SaleDateConverted date;

-- UPDATE nashvillehousing
-- SET SaleDateConverted = str_to_date(SaleDate, '%d-%M-%y');




 --------------------------------------------------------------------------------------------------------------------------

-- Convert blank spaces in PropertyAddress, OwnerName, OwnerAddress and TaxDistrict to NULL




-- To count the number of records that have space in their fields

select count(TaxDistrict) -- , count(OwnerAddress), count(OwnerName), count (PropertyAddress)
from nashvillehousing
where TaxDistrict = ''; -- OwnerAddress = '';



alter table nashvillehousing
add column propertyaddresswnull nvarchar(150);


update nashvillehousing
set propertyaddresswnull = PropertyAddress;


update nashvillehousing
set propertyaddresswnull = null
where propertyaddresswnull = '';


alter table nashvillehousing
add column OwnerNamewnull nvarchar(150), 
add column OwnerAddresswnull nvarchar(150), 
add column TaxDistrictwnull nvarchar(150);


update nashvillehousing
set OwnerNamewnull = OwnerName, OwnerAddresswnull = OwnerAddress,
	TaxDistrictwnull = TaxDistrict;


update nashvillehousing
set OwnerNamewnull = null
where OwnerName = '';


update nashvillehousing
set OwnerAddresswnull = null
where OwnerAddress = '';


update nashvillehousing
set TaxDistrictwnull = null
where TaxDistrict = '';




--------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data




SELECT a.UniqueID, a.ParcelID, a.propertyaddresswnull, 
	b.UniqueID, b.ParcelID, b.PropertyAddresswnull, 
	ifnull(a.propertyaddresswnull, b.propertyaddresswnull)
FROM nashvillehousing a
JOIN nashvillehousing b
	ON a.parcelid = b.parcelid
    AND a.uniqueid != b.uniqueid
where a.propertyaddresswnull is null;



update nashvillehousing a
JOIN nashvillehousing b
	ON a.parcelid = b.parcelid
    AND a.uniqueid != b.uniqueid
set a.propertyaddresswnull = ifnull(a.propertyaddresswnull, b.propertyaddresswnull)
where a.propertyaddresswnull is null;



#-- Timeout error thrown
#-- New versions of MySQL WorkBench have an option to change specific timeouts.
#-- For me it was under Edit → Preferences → SQL Editor → DBMS connection read time out (in seconds): 600
#-- Changed the value to 6000.




--------------------------------------------------------------------------------------------------------------------------

-- Removing extra spaces from PropertyAddress




SELECT propertyaddresswnull 
FROM nashvillehousing
ORDER BY propertyaddresswnull asc;

select propertyaddresswnull, trim(propertyaddresswnull)
from nashvillehousing
order by propertyaddresswnull asc;

update nashvillehousing
set propertyaddresswnull = trim(propertyaddresswnull);

select propertyaddresswnull
from nashvillehousing
where propertyaddresswnull like '%12TH%'
order by propertyaddresswnull asc;




--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Property Address into Individual Columns (Address, City)




select substring_index(propertyaddresswnull, ',', 1), -- gets the first substring before the delimiter ',' from the beginning of the string
	substring_index(propertyaddresswnull, ',', -1) -- gets the first substring before the delimiter ',' from the end of the string
from nashvillehousing;


alter table nashvillehousing
add column PropertySplitAddress nvarchar(255);


update nashvillehousing
set PropertySplitAddress = substring_index(propertyaddresswnull, ',', 1);


alter table nashvillehousing
add column PropertySplitCity nvarchar(255);


update nashvillehousing
set PropertySplitCity = substring_index(propertyaddresswnull, ',', -1);




--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Owner Address into Individual Columns (Address, City, State)




select substring_index(OwnerAddresswnull, ',', 1), -- gets the first substring before the delimiter ',' from the beginning of the string
	substring_index(substring_index(OwnerAddresswnull, ',', 2), ',', -1),
    substring_index(OwnerAddresswnull, ',', -1) -- gets the first substring before the delimiter ',' from the end of the string
from nashvillehousing;


alter table nashvillehousing
add column OwnerSplitAddress nvarchar(255),
add column OwnerSplitCity nvarchar(255),
add column OwnerSplitState nvarchar(255);


update nashvillehousing
set OwnerSplitAddress = substring_index(OwnerAddresswnull, ',', 1);


update nashvillehousing
set OwnerSplitCity = substring_index(substring_index(OwnerAddresswnull, ',', 2), ',', -1);


update nashvillehousing
set OwnerSplitState = substring_index(OwnerAddresswnull, ',', -1);




--------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field




select distinct(SoldAsVacant), count(SoldAsVacant)
from nashvillehousing
group by SoldAsVacant
order by 2;


select SoldAsVacant,
	CASE When SoldAsVacant = 'y' THEN	'Yes'
		 When SoldAsVacant = 'n' THEN	'No'
		 ELSE SoldAsVacant
	END
from nashvillehousing
order by 1;


update nashvillehousing
set SoldAsVacant =
	CASE When SoldAsVacant = 'y' THEN	'Yes'
		 When SoldAsVacant = 'n' THEN	'No'
		 ELSE SoldAsVacant
	END;




-----------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates




#-- Trial #1

#-- Following code creates a CTE and then deletes duplicate rows from the CTE 
#-- but you cannot delete from a CTE in MYSQL (this method works in Microsoft SQL Server)

-- WITH RowNumDuplicate as 
-- (
-- select *,
-- 	row_number() over
--     (	
-- 		partition by parcelID, propertyaddresswnull, SaleDateConverted,
-- 			saleprice, LegalReference, OwnerNamewnull, OwnerAddresswnull
-- 	) as row_num
-- from nashvillehousing
-- ) 

-- -- checking if the CTE worked

-- select *
-- from RowNumDuplicate
-- where row_num>1
-- order by propertyaddresswnull;

-- -- checking whether the code is giving duplicates

-- -- select *
-- -- from nashvillehousing
-- -- where parcelID = '081 02 0 144.00';

-- -- delete
-- -- from RowNumDuplicate
-- -- where row_num>1;



#-- Trial #2

# Following method adds a column for Windows function but you can't
# use Windows functions with update statements

-- alter table nashvillehousing
-- add column rownumduplicate int;

-- update nashvillehousing
-- set rownumduplicate = row_number() over
--     (	
-- 		partition by parcelID, propertyaddresswnull, SaleDateConverted,
-- 			saleprice, LegalReference, OwnerNamewnull, OwnerAddresswnull
-- 	);



SELECT * FROM nashvillehousing 
WHERE UniqueID IN
(
 	SELECT UniqueID 
 	FROM
 	(
		SELECT UniqueID, row_number() over
		(	
			partition by parcelID, propertyaddresswnull, SaleDateConverted,
				saleprice, LegalReference, OwnerNamewnull, OwnerAddresswnull
		) AS row_num 
		FROM nashvillehousing
	 ) nh
	WHERE row_num>1
);


DELETE FROM nashvillehousing 
WHERE UniqueID IN
(
	SELECT UniqueID 
	FROM
	(
		SELECT UniqueID, row_number() over
		(	
			partition by parcelID, propertyaddresswnull, SaleDateConverted,
				saleprice, LegalReference, OwnerNamewnull, OwnerAddresswnull
		) AS row_num 
		FROM nashvillehousing
	 ) nh
	WHERE row_num>1
);




---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns




ALTER TABLE nashvillehousing
DROP COLUMN PropertyAddress, 
DROP COLUMN SaleDate, 
DROP COLUMN OwnerName, 
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict,
DROP COLUMN rownumduplicate; 


ALTER TABLE nashvillehousing
RENAME COLUMN SaleDateConverted to SaleDate, 
RENAME COLUMN propertyaddresswnull to PropertyAddress,
RENAME COLUMN OwnerNamewnull to OwnerName,
RENAME COLUMN OwnerAddresswnull to OwnerAddress,
RENAME COLUMN TaxDistrictwnull to TaxDistrict;




