-- Selecting tables we're going to use

SELECT
	*
FROM [Google Play Store].dbo.googleplaystore

SELECT
	*
FROM [Google Play Store].dbo.googleplaystore_user_reviews

-- Removing timestamps in lastupdated column

ALTER TABLE dbo.googleplaystore
ALTER COLUMN LastUpdated DATE

-- Removing apps in unknown category (1.9)

DELETE FROM [Google Play Store].dbo.googleplaystore
WHERE App IN
	(SELECT
		App
	FROM [Google Play Store].dbo.googleplaystore
	WHERE Category = '1.9')

-- Changing installs column into an int datatype by removing strings

UPDATE [Google Play Store].dbo.googleplaystore
SET Installs = REPLACE(Installs, '+', '')

UPDATE [Google Play Store].dbo.googleplaystore
SET Installs = REPLACE(Installs, ',', '')

ALTER TABLE [Google Play Store].dbo.googleplaystore
ALTER COLUMN Installs INT

-- Apps with duplicates entries

SELECT
	App,
	COUNT(*) AS app_cnt
FROM [Google Play Store].dbo.googleplaystore
GROUP BY App
HAVING COUNT(*) > 1
ORDER BY app_cnt DESC

-- Percentage of apps for everyone

SELECT
	CONCAT(LEFT(ROUND(100.0 * COUNT(CASE WHEN [Content Rating] = 'Everyone' THEN 1 ELSE NULL END)/
	COUNT(*), 2), 5), '%') AS apps_foreveryone
FROM [Google Play Store].dbo.googleplaystore

-- Percentage of apps for teen

SELECT
	CONCAT(LEFT(ROUND(100.0 * COUNT(CASE WHEN [Content Rating] = 'Teen' THEN 1 ELSE NULL END)/
	COUNT(*), 2), 5), '%') AS apps_foreveryone
FROM [Google Play Store].dbo.googleplaystore

-- Percentage of apps for mature 17+

SELECT
	CONCAT(LEFT(ROUND(100.0 * COUNT(CASE WHEN [Content Rating] = 'Mature 17+' THEN 1 ELSE NULL END)/
	COUNT(*), 2), 4), '%') AS apps_foreveryone
FROM [Google Play Store].dbo.googleplaystore

-- Apps with a 4.5 rating or higher for everyone and has over or equal to 1000000 installs

SELECT DISTINCT
	*
FROM [Google Play Store].dbo.googleplaystore
WHERE Rating >= 4.5 AND [Content Rating] LIKE 'Everyone%' AND Installs >= 1000000 
	AND Reviews IN (SELECT MAX(Reviews) FROM [Google Play Store].dbo.googleplaystore GROUP BY App) 
ORDER BY Installs DESC, Reviews DESC

-- Percentage of apps that have a 4.5 rating or higher

SELECT
	CONCAT(LEFT(ROUND(100.0 * COUNT(CASE WHEN Rating >= 4.5 THEN 1 ELSE NULL END)/
	COUNT(*), 2), 5), '%') AS percentage_of_apps
FROM [Google Play Store].dbo.googleplaystore
WHERE Rating IS NOT NULL

-- Apps with a 4.0 rating or lower for everyone and has over or equal to 1000000 installs 

SELECT DISTINCT
	*
FROM [Google Play Store].dbo.googleplaystore
WHERE Rating <= 4.0 AND [Content Rating] LIKE 'Everyone%' AND Installs >= 1000000 
	AND Reviews IN (SELECT MAX(Reviews) FROM [Google Play Store].dbo.googleplaystore GROUP BY App) 
ORDER BY Installs DESC, Reviews DESC 

-- Percentage of apps that have a 4.0 rating or lower

SELECT
	CONCAT(LEFT(ROUND(100.0 * COUNT(CASE WHEN Rating <= 4.0 THEN 1 ELSE NULL END)/
	COUNT(*), 2), 5), '%') AS percentage_of_apps
FROM [Google Play Store].dbo.googleplaystore
WHERE Rating IS NOT NULL

-- Seeing which category is the most abundant

SELECT
	Category,
	COUNT(*) AS app_cnt
FROM [Google Play Store].dbo.googleplaystore
GROUP BY Category
ORDER BY app_cnt DESC

-- Seeing the average rating for different categories

SELECT
	Category,
	ROUND(AVG(Rating), 2) AS avg_rating
FROM [Google Play Store].dbo.googleplaystore
GROUP BY Category
ORDER BY avg_rating DESC

-- Counting family apps that have a 4.5 rating or higher 

SELECT
	COUNT(CASE WHEN Rating >= 4.5 AND Category = 'FAMILY' THEN 1 ELSE NULL END) AS app_cnt
FROM [Google Play Store].dbo.googleplaystore

-- Percentage out of total family apps that have a 4.5 rating or higher 

SELECT
	REPLACE(CONCAT(ROUND(100.0 * COUNT(CASE WHEN Rating >= 4.5 AND Category = 'FAMILY' THEN 1 ELSE NULL END)/
	COUNT(*), 2), '%'), '0', '') AS percentage_of_apps
FROM [Google Play Store].dbo.googleplaystore
WHERE Category = 'FAMILY' AND Rating IS NOT NULL

-- Counting game apps that have a 4.5 rating or higher 

SELECT
	COUNT(CASE WHEN Rating >= 4.5 AND Category = 'GAME' THEN 1 ELSE NULL END) AS app_count
FROM [Google Play Store].dbo.googleplaystore

-- Percentage out of total game apps that have a 4.5 rating or higher 

SELECT
	REPLACE(CONCAT(ROUND(100.0 * COUNT(CASE WHEN Rating >= 4.5 AND Category = 'GAME' THEN 1 ELSE NULL END)
	/COUNT(*), 2), '%'), '0', '') AS percentage_of_apps
FROM [Google Play Store].dbo.googleplaystore
WHERE Category = 'GAME' AND Rating IS NOT NULL

-- Looking at the top installed family app

WITH cte 
AS (
	SELECT
		App,
		DENSE_RANK() OVER(ORDER BY MAX(Installs) DESC) AS rk
	FROM [Google Play Store].dbo.googleplaystore
	WHERE Category = 'FAMILY'
	GROUP BY App
	)

SELECT
	App AS top_family_app
FROM cte
WHERE rk = 1

-- Looking at the top installed game app

WITH cte 
AS (
	SELECT
		App,
		DENSE_RANK() OVER(ORDER BY MAX(Installs) DESC) AS rk
	FROM [Google Play Store].dbo.googleplaystore
	WHERE Category = 'GAME'
	GROUP BY App
	)

SELECT
	App AS top_game_app
FROM cte
WHERE rk = 1

-- Looking at the most popular apps on google play store

WITH cte
AS (
	SELECT 
		App,
		MAX(Installs) AS total_installs
	FROM [Google Play Store].dbo.googleplaystore
	GROUP BY App
	)

SELECT DISTINCT
	App,
	total_installs
FROM cte
WHERE total_installs = (SELECT MAX(Installs) FROM [Google Play Store].dbo.googleplaystore)
ORDER BY total_installs DESC

-- Looking at the most popular free apps by total installs and reviews

SELECT
	App,
	Rating,
	Price,
	Genres,
	MAX(Reviews) AS Reviews,
	MAX(Installs) AS Installs
FROM [Google Play Store].dbo.googleplaystore 
WHERE Type = 'Free' 
GROUP BY App, Rating, Price, Genres
ORDER BY Installs DESC, Reviews DESC

-- Looking at the most popular paid apps by total installs and reviews

SELECT
	App,
	Rating,
	Price,
	Genres,
	MAX(Reviews) AS Reviews,
	MAX(Installs) AS Installs
FROM [Google Play Store].dbo.googleplaystore 
WHERE Type = 'Paid' 
GROUP BY App, Rating, Price, Genres
ORDER BY Installs DESC, Reviews DESC

-- Looking at the most expensive apps 

SELECT
	App,
	MAX(Price) AS Price
FROM [Google Play Store].dbo.googleplaystore
GROUP BY App
ORDER BY Price DESC

-- Seeing which apps are the biggest

WITH cte
AS (
	SELECT
		App,
		MAX(Size) AS app_size
	FROM [Google Play Store].dbo.googleplaystore
	WHERE Size NOT IN 
			(SELECT 
				Size 
			FROM [Google Play Store].dbo.googleplaystore 
			WHERE Size = 'Varies with device')
	GROUP BY App
	)

SELECT
	App,
	app_size
FROM cte
WHERE app_size = (SELECT MAX(app_size) FROM cte)

-- Classifying apps as popular, big, rising, or small

SELECT
	App,
	CASE WHEN Installs >= 10000000 THEN 'Popular'
		WHEN Installs BETWEEN 1000000 AND 9999999 THEN 'Big'
		WHEN Installs BETWEEN 100000 AND 999999 THEN 'Rising'
		ELSE 'Small' END AS classification
FROM [Google Play Store].dbo.googleplaystore
ORDER BY App

-- Looking at the number of positive and negative sentiments of some apps

WITH positive
AS (
	SELECT DISTINCT
		gp.App,
		COUNT(gp2.Sentiment) AS positive_sentiment
	FROM [Google Play Store].dbo.googleplaystore gp
	JOIN [Google Play Store].dbo.googleplaystore_user_reviews gp2
	ON gp.App = gp2.App
	WHERE gp2.Sentiment = 'Positive'
	GROUP BY gp.App
	)
,
negative
AS (
	SELECT DISTINCT
		gp.App,
		COUNT(gp2.Sentiment) AS negative_sentiment
	FROM [Google Play Store].dbo.googleplaystore gp
	JOIN [Google Play Store].dbo.googleplaystore_user_reviews gp2
	ON gp.App = gp2.App
	WHERE gp2.Sentiment = 'Negative'
	GROUP BY gp.App
	)

SELECT
	p.App,
	positive_sentiment,
	negative_sentiment
FROM positive p 
JOIN negative n
ON p.App = n.App
ORDER BY positive_sentiment DESC

	
