-- SELECTING TABLES WE'RE GOING TO USE

SELECT
	*
FROM [Google Play Store].dbo.googleplaystore

SELECT
	*
FROM [Google Play Store].dbo.googleplaystore_user_reviews

-- REMOVING TIMESTAMPS IN LASTUPDATED COLUMN

ALTER TABLE dbo.googleplaystore
ALTER COLUMN LastUpdated DATE

-- REMOVING APPS IN UNKNOWN CATEGORY (1.9)

DELETE FROM [Google Play Store].dbo.googleplaystore
WHERE App IN
		(SELECT
			App
		FROM [Google Play Store].dbo.googleplaystore
		WHERE Category = '1.9')

-- CHANGING INSTALLS COLUMN INTO AN INT DATATYPE BY REMOVING STRINGS

UPDATE [Google Play Store].dbo.googleplaystore
SET Installs = REPLACE(Installs, '+', '')

UPDATE [Google Play Store].dbo.googleplaystore
SET Installs = REPLACE(Installs, ',', '')

ALTER TABLE [Google Play Store].dbo.googleplaystore
ALTER COLUMN Installs INT

-- APPS WITH A 4.5 RATING OR HIGHER FOR EVERYONE AND HAS OVER OR EQUAL TO 1000000 Installs

SELECT DISTINCT
	*
FROM [Google Play Store].dbo.googleplaystore
WHERE Rating >= 4.5 AND [Content Rating] LIKE 'Everyone%' AND Installs >= 1000000 
	AND Reviews IN (SELECT MAX(Reviews) FROM [Google Play Store].dbo.googleplaystore GROUP BY App) 
ORDER BY Installs DESC, Reviews DESC

-- PERCENTAGE OF APPS THAT HAVE A 4.5 RATING OR HIGHER

SELECT
	COUNT(CASE 
			WHEN Rating >= 4.5 THEN App
		END) * 1.0/COUNT(*) * 100 AS percentage_of_apps
FROM [Google Play Store].dbo.googleplaystore
WHERE Rating IS NOT NULL

-- APPS WITH A 4.0 RATING OR LOWER FOR EVERYONE AND HAS OVER OR EQUAL TO 1000000 Installs 

SELECT DISTINCT
	*
FROM [Google Play Store].dbo.googleplaystore
WHERE Rating <= 4.0 AND [Content Rating] LIKE 'Everyone%' AND Installs >= 1000000 
	AND Reviews IN (SELECT MAX(Reviews) FROM [Google Play Store].dbo.googleplaystore GROUP BY App) 
ORDER BY Installs DESC, Reviews DESC

-- PERCENTAGE OF APPS THAT HAVE a 4.0 RATING OR LOWER

SELECT
	COUNT(CASE 
			WHEN Rating <= 4.0 THEN App
		END) * 1.0/COUNT(*) * 100 AS percentage_of_apps
FROM [Google Play Store].dbo.googleplaystore
WHERE Rating IS NOT NULL

-- SEEING WHICH CATEGORY IS THE MOST ABUNDANT

SELECT
	Category,
	COUNT(*) AS num_of_genres
FROM [Google Play Store].dbo.googleplaystore
GROUP BY Category
ORDER BY num_of_genres DESC

-- SEEING THE AVERAGE RATING FOR DIFFERENT CATEGORIES

SELECT
	Category,
	ROUND(AVG(Rating), 2) AS avg_rating
FROM [Google Play Store].dbo.googleplaystore
GROUP BY Category
ORDER BY avg_rating DESC

-- COUNTING FAMILY APPS THAT HAVE A 4.5 RATING OR HIGHER 

SELECT
	COUNT(CASE
			WHEN Rating >= 4.5 AND Category = 'FAMILY' THEN App
		END) AS app_count
FROM [Google Play Store].dbo.googleplaystore

-- PERCENTAGE OUT OF TOTAL FAMILY APPS THAT HAVE A 4.5 RATING OR HIGHER 

SELECT
	COUNT(CASE
			WHEN Rating >= 4.5 AND Category = 'FAMILY' THEN App
		END) * 1.0/COUNT(*) * 100 AS percentage_of_apps
FROM [Google Play Store].dbo.googleplaystore
WHERE Category = 'FAMILY' AND Rating IS NOT NULL

-- COUNTING GAME APPS THAT HAVE A 4.5 RATING OR HIGHER 

SELECT
	COUNT(CASE
			WHEN Rating >= 4.5 AND Category = 'GAME' THEN App
		END) AS app_count
FROM [Google Play Store].dbo.googleplaystore

-- PERCENTAGE OUT OF TOTAL GAME APPS THAT HAVE A 4.5 RATING OR HIGHER 

SELECT
	COUNT(CASE
			WHEN Rating >= 4.5 AND Category = 'GAME' THEN App
		END) * 1.0/COUNT(*) * 100 AS percentage_of_apps
FROM [Google Play Store].dbo.googleplaystore
WHERE Category = 'GAME' AND Rating IS NOT NULL

-- LOOKING AT THE TOP INSTALLED FAMILY APP

WITH cte AS
(SELECT
	App,
	DENSE_RANK() OVER(ORDER BY MAX(Installs) DESC) AS rk
FROM [Google Play Store].dbo.googleplaystore
WHERE Category = 'FAMILY'
GROUP BY App)

SELECT
	*
FROM cte
WHERE rk = 1

-- LOOKING AT THE TOP INSTALLED GAME APP

WITH cte AS
(SELECT
	App,
	DENSE_RANK() OVER(ORDER BY MAX(Installs) DESC) AS rk
FROM [Google Play Store].dbo.googleplaystore
WHERE Category = 'GAME'
GROUP BY App)

SELECT
	*
FROM cte
WHERE rk = 1

-- LOOKING AT THE MOST POPULAR APPS ON GOOGLE PLAY STORE

SELECT 
	App,
	MAX(Installs) AS total_installs
FROM [Google Play Store].dbo.googleplaystore
GROUP BY App
HAVING MAX(Installs) >= 1000000000
ORDER BY total_installs DESC

-- LOOKING AT THE MOST POPULAR FREE APPS BY TOTAL INSTALLS

SELECT DISTINCT
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

-- LOOKING AT THE MOST POPULAR PAID APPS BY TOTAL INSTALLS

SELECT DISTINCT
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

-- LOOKING AT THE MOST EXPENSIVE APPS 

SELECT DISTINCT
	App,
	MAX(Price) AS Price
FROM [Google Play Store].dbo.googleplaystore
GROUP BY App
ORDER BY Price DESC

-- SEEING WHICH APPS ARE THE BIGGEST

SELECT
	App,
	MAX(Size) AS largest_app
FROM [Google Play Store].dbo.googleplaystore
WHERE Size NOT IN 
		(SELECT 
			Size 
		FROM [Google Play Store].dbo.googleplaystore 
		WHERE Size = 'Varies with device')
GROUP BY App
ORDER BY largest_app DESC

-- CLASSIFYING APPS AS POPULAR, BIG, RISING, OR SMALL

SELECT
	App,
	CASE 
		WHEN Installs >= 10000000 THEN 'Popular'
		WHEN Installs BETWEEN 1000000 AND 9999999 THEN 'Big'
		WHEN Installs BETWEEN 100000 AND 999999 THEN 'Rising'
		ELSE 'Small' END AS classification
FROM [Google Play Store].dbo.googleplaystore

-- LOOKING AT THE AMOUNT OF POSITIVES VS NEGATIVES REVIEWS FOR EACH APP

WITH positive AS
		(SELECT
			g1.App,
			g2.Sentiment,
			COUNT(g2.Sentiment) AS num_of_sentiments
		FROM [Google Play Store].dbo.googleplaystore g1
		JOIN [Google Play Store].dbo.googleplaystore_user_reviews g2
		ON g1.App = g2.App
		WHERE g2.Sentiment = 'Positive'
		GROUP BY g1.App, g2.Sentiment)
,
negative AS
		(SELECT
			g1.App,
			g2.Sentiment,
			COUNT(g2.Sentiment) AS num_of_sentiments
		FROM [Google Play Store].dbo.googleplaystore g1
		JOIN [Google Play Store].dbo.googleplaystore_user_reviews g2
		ON g1.App = g2.App
		WHERE g2.Sentiment = 'Negative'
		GROUP BY g1.App, g2.Sentiment)

SELECT
	p.App,
	p.Sentiment,
	p.num_of_sentiments,
	n.Sentiment,
	n.num_of_sentiments,
	SUM(p.num_of_sentiments + n.num_of_sentiments) AS total
FROM positive p
JOIN negative n
ON p.App = n.App
GROUP BY p.App, p.Sentiment, p.num_of_sentiments, n.Sentiment, n.num_of_sentiments
ORDER BY total DESC

