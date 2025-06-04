-- SQLite

-- Question 1: How many movies have more than one spoken language?

-- We do NOT need to join with the `movies` table because `movie_languages.movie_id`
-- maps directly to distinct movies. Can verify this by counting distinct movie_ids:
-- SELECT COUNT(DISTINCT movie_id) FROM movie_languages;
-- This returns 45,430 which exactly matches the row count of the `movies` table.
-- Therefore, every movie_id in `movie_languages` corresponds to a valid movie.


SELECT COUNT(*) AS movies_with_multiple_languages
FROM (
    SELECT movie_id
    FROM movie_languages
    GROUP BY movie_id
    HAVING COUNT(*) > 1
) AS sub;

-- Returns 7891


-- Question 2: What are the top 3 movie(s) in revenue in the 1990s and the 2000s, respectively?

SELECT title, revenue, decade
FROM (
    SELECT 
        title, 
        revenue, 
        strftime('%Y', release_date) AS year, 
        '1990s' AS decade
    FROM movies
    WHERE strftime('%Y', release_date) BETWEEN '1990' AND '1999'
    ORDER BY revenue DESC
    LIMIT 3
)

UNION ALL

SELECT title, revenue, decade
FROM (
    SELECT 
        title, 
        revenue, 
        strftime('%Y', release_date) AS year, 
        '2000s' AS decade
    FROM movies
    WHERE strftime('%Y', release_date) BETWEEN '2000' AND '2009'
    ORDER BY revenue DESC
    LIMIT 3
);

-- returns 
-- Titanic 1990s 
-- Star Wars: Episode I - The Phantom Menace 1990s 
-- Jurassic Park 1990s 
-- Avatar 2000s 
-- The Lord of the Rings: The Return of the King 2000s 
-- Pirates of the Caribbean: Dead Man's Chest 2000s 


-- Question 3: What are the annual profits for movies produced by `Walt Disney Pictures` or `Walt Disney Studios Motion Pictures`?

SELECT 
    strftime('%Y', m.release_date) AS year,
    SUM(m.revenue) AS annual_profit
FROM 
    movies AS m
JOIN 
    production_companies AS pc ON m.id = pc.movie_id
WHERE 
    pc.company_name IN ('Walt Disney Pictures', 'Walt Disney Studios Motion Pictures')
GROUP BY 
    strftime('%Y', m.release_date)
HAVING 
    annual_profit > 0
ORDER BY 
    year;

-- returns
-- 1940	83320000
-- 1967	205843612
-- 1980	5000000
-- 1982	33000000
-- 1983	5656087
-- 1985	21288692
-- 1986	57190163
-- 1988	74151346
-- 1989	222300000
-- 1990	47431461
-- 1991	474143713
-- 1992	589994178
-- 1993	93413558
-- 1994	1031649649
-- 1995	399117547
-- 1996	516786223
-- 1997	453833826
-- 1998	672141259
-- 1999	575724671
-- 2000	959148737
-- 2001	931497515
-- 2002	632822505
-- 2003	1155787148
-- 2004	1207325950
-- 2005	622888032
-- 2006	1999550440
-- 2007	2699787159
-- 2008	951865570
-- 2009	1239166126
-- 2010	3695008268
-- 2011	1807340435
-- 2012	874977182
-- 2013	2931270366
-- 2014	2717514948
-- 2015	1987916055
-- 2016	8658143513
-- 2017	3270664523


-- Question 4: Which movie has the 3rd highest average rating in the 2000s? If there are ties, list the ones with the most ratings left by users.

-- If there are ties the ties are broken by rating count. 
-- If tie cannot be broken by rating count then all tied movies will share same rank

WITH RankedMovies AS (
    SELECT 
        m.title,
        m.release_date,
        COUNT(mr.rating) AS num_ratings,
        AVG(mr.rating) AS avg_rating,
        DENSE_RANK() OVER (
            ORDER BY AVG(mr.rating) DESC, COUNT(mr.rating) DESC
        ) AS rank
    FROM 
        movies m
    JOIN 
        movie_ratings mr ON m.id = mr.movie_id
    JOIN 
        movies_f mf ON m.id = mf.movie_id
    WHERE 
        m.release_date BETWEEN '2000-01-01' AND '2009-12-31'
    GROUP BY 
        m.id
)
SELECT title, release_date, num_ratings, avg_rating
FROM RankedMovies
WHERE rank = 3;

-- returns
-- title, release_date, num_ratings, avg_rating
-- 4 Elements	2006-11-30 00:00:00	1	4.5
-- National Geographic: Hitler's Stealth Fighter	2009-01-01 00:00:00	1	4.5


-- Intermediate table to help answer question 4
SELECT 
    m.title,
    m.release_date,
    COUNT(mr.rating) AS num_ratings,
    AVG(mr.rating) AS avg_rating
FROM 
    movies m
JOIN 
    movie_ratings mr ON m.id = mr.movie_id
JOIN 
    movies_f mf ON m.id = mf.movie_id
WHERE 
    m.release_date BETWEEN '2000-01-01' AND '2009-12-31'
GROUP BY 
    m.id
ORDER BY 
    avg_rating DESC, 
    num_ratings DESC;

-- returns
-- title, release_date, num_ratings, avg_rating
-- Lightheaded	2009-08-04 00:00:00	1	5.0
-- Khel	2003-11-11 00:00:00	1	5.0
-- Refugee	2000-06-30 00:00:00	1	5.0
-- Evel Knievel	2004-07-30 00:00:00	2	4.5
-- Hoop Reality	2007-07-01 00:00:00	2	4.5
-- Just Friends?	2009-12-17 00:00:00	2	4.5
-- 4 Elements	2006-11-30 00:00:00	1	4.5
-- National Geographic: Hitler's Stealth Fighter	2009-01-01 00:00:00	1	4.5
-- The Million Dollar Hotel	2000-02-09 00:00:00	91082	4.429014514393623

-- First place would be shared between Lightheaded, Khel, and Refugee since they each have a avg rating of 5 and a rating count of 1
-- Second place would be shared between Evel Knievel, Hoop Reality and Just Friends? since they each have a avg rating of 4.5 and a rating count of 2
-- Third place would be 4 Elements and National Geographic: Hitler's Stealth Fighter since they each have a avg rating of 4.5 and a rating count of 1