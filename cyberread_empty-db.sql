-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Gép: 127.0.0.1
-- Létrehozás ideje: 2024. Ápr 23. 21:29
-- Kiszolgáló verziója: 10.4.32-MariaDB
-- PHP verzió: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Adatbázis: `cyberread`
--
CREATE DATABASE IF NOT EXISTS `cyberread` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `cyberread`;

DELIMITER $$
--
-- Eljárások
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `addBook` (IN `userIdIN` INT, IN `titleIN` VARCHAR(50), IN `descriptionIN` VARCHAR(1000), IN `targetAudienceIdIN` INT, IN `languageIdIN` INT, IN `adultFictionIN` BOOLEAN, IN `categoryIdIN` INT, IN `statusIN` INT, IN `priceIN` INT, IN `coverImageIN` VARCHAR(100), IN `fileIN` VARCHAR(100), IN `bankAccountNumberIN` VARCHAR(30), IN `chapterNumberIN` INT, IN `freeChapterNumberIN` INT, OUT `result` INT)   BEGIN

	DECLARE statusText VARCHAR(50);
 
    IF NOT EXISTS (SELECT * FROM `targetaudience` WHERE `targetaudience`.`id` = targetAudienceIdIN) AND NOT EXISTS (SELECT * FROM `language` WHERE `language`.`id` = languageIdIN) AND NOT EXISTS (SELECT * FROM `category` WHERE `category`.`id` = categoryIdIN) THEN
    	SET result = 8;
    ELSEIF NOT EXISTS (SELECT * FROM `language` WHERE `language`.`id` = languageIdIN) AND NOT EXISTS (SELECT * FROM `category` WHERE `category`.`id` = categoryIdIN) THEN
    	SET result = 7;
    ELSEIF NOT EXISTS (SELECT * FROM `targetaudience` WHERE `targetaudience`.`id` = targetAudienceIdIN) AND NOT EXISTS (SELECT * FROM `category` WHERE `category`.`id` = categoryIdIN) THEN
    	SET result = 6;
    ELSEIF NOT EXISTS (SELECT * FROM `targetaudience` WHERE `targetaudience`.`id` = targetAudienceIdIN) AND NOT EXISTS (SELECT * FROM `language` WHERE `language`.`id` = languageIdIN) THEN
    	SET result = 5;
    ELSEIF NOT EXISTS (SELECT * FROM `category` WHERE `category`.`id` = categoryIdIN) THEN
    	SET result = 4;
    ELSEIF NOT EXISTS (SELECT * FROM `language` WHERE `language`.`id` = languageIdIN) THEN
    	SET result = 3;
    ELSEIF NOT EXISTS (SELECT * FROM `targetaudience` WHERE `targetaudience`.`id` = targetAudienceIdIN) THEN
    	SET result = 2;
    ELSE

        IF statusIN IS NOT NULL THEN
            IF statusIN = 1 THEN
                SET statusText = "looking for a publisher";
                INSERT INTO `book` (`book`.`writerId`,`book`.`title`, `book`.`description`, `book`.`targetAudienceId`, `book`.`languageId`, `book`.`adultFiction`, `book`.`categoryId`, `book`.`status`, `book`.`coverImage`, `book`.`file`, `book`.`chapterNumber`, `book`.`freeChapterNumber`, `book`.`price`)
                VALUES (userIdIN, titleIN, descriptionIN, targetAudienceIdIN, languageIdIN, adultFictionIN, categoryIdIN, statusText, coverImageIN, fileIN, chapterNumberIN, freeChapterNumberIN, NULL);
                SET result = 1;
            ELSEIF statusIN = 2 THEN
                SET statusText = "self-published";

                INSERT INTO `book` (`book`.`writerId`,`book`.`title`, `book`.`description`, `book`.`targetAudienceId`, `book`.`languageId`, `book`.`adultFiction`, `book`.`categoryId`, `book`.`status`, `book`.`price`, `book`.`coverImage`, `book`.`file`, `book`.`bankAccountNumber`, `book`.`chapterNumber`, `book`.`freeChapterNumber`)
                VALUES (userIdIN, titleIN, descriptionIN, targetAudienceIdIN, languageIdIN, adultFictionIN, categoryIdIN, statusText, priceIN, coverImageIN, fileIN, bankAccountNumberIN, chapterNumberIN, freeChapterNumberIN);
                SET result = 1;
            END IF;
        END IF;
    END IF;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `addCategoryInterest` (IN `userIdIN` INT, IN `categoryIds` TEXT)   BEGIN

    DECLARE counter INT DEFAULT 1;
    DECLARE categoryId INT(11);

    WHILE counter <= LENGTH(categoryIds) - LENGTH(REPLACE(categoryIds, ',', '')) + 1 DO
        SET categoryId = SUBSTRING_INDEX(SUBSTRING_INDEX(categoryIds, ',', counter), ',', -1);
        
        IF NOT EXISTS(SELECT * FROM `categoryinterest` WHERE `categoryinterest`.`userId` = userIdIN AND `categoryinterest`.`categoryId` = categoryId) THEN
            INSERT INTO `categoryinterest` (`categoryinterest`.`userId`, `categoryinterest`.`categoryId`) 
            VALUES (userIdIN, categoryId);
        END IF;

        SET counter = counter + 1;
    END WHILE;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `addPost` (IN `userIdIN` INT, IN `descriptionIN` VARCHAR(1000))   INSERT INTO `post` (`post`.`userId`, `post`.`description`)
VALUES (userIdIN, descriptionIN)$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteBook` (IN `userIdIN` INT, IN `bookIdIN` INT, OUT `result` INT)   BEGIN

	IF (SELECT `book`.`writerId` FROM `book` WHERE `book`.`id` = bookIdIN) != userIdIN THEN
		SET result = 3;
    ELSEIF EXISTS (SELECT * FROM `book` WHERE `book`.`id` = bookIdIN) THEN
    	DELETE FROM `book`
        WHERE `book`.`id` = bookIdIN;
        
        SET result = 1;
    ELSE
    	SET result = 2;
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deletePost` (IN `userIdIN` INT, IN `postIdIN` INT, OUT `result` INT)   BEGIN

	IF (SELECT `post`.`userId` FROM `post` WHERE `post`.`id` = postIdIN) != userIdIN THEN
    	SET result = 3;
    ELSEIF EXISTS (SELECT * FROM `post` WHERE `post`.`userId` = userIdIN AND `post`.`id` = postIdIN) THEN
    	DELETE FROM `post`
        WHERE `post`.`userId` = userIdIN AND `post`.`id` = postIdIN;
        
        SET result = 1;
    ELSE
    	SET result = 2;
    END IF;
	
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteSavedBook` (IN `userIdIN` INT, IN `bookIdIN` INT, OUT `result` INT)   BEGIN

	IF NOT EXISTS (SELECT * FROM `saved` WHERE `saved`.`userId` = userIdIN AND `saved`.`bookId` = bookIdIN) THEN
    	SET result = 2;
    ELSE
    	DELETE FROM `saved`
        WHERE `saved`.`userId` = userIdIN AND `saved`.`bookId` = bookIdIN;
        
        SET result = 1;
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `followUser` (IN `userIdIN` INT, IN `followedUsernameIN` VARCHAR(50), OUT `result` INT)   BEGIN

	DECLARE followedUserId INT;
    
    SELECT `user`.`id` INTO followedUserId FROM `user` WHERE `user`.`username` = followedUsernameIN;

	IF userIdIN = followedUserId THEN
    	SET result = 3;
	ELSEIF NOT EXISTS (SELECT * FROM `follow` WHERE `follow`.`followerId` = userIdIN AND `follow`.`followedId` = followedUserId) THEN
    	INSERT INTO `follow` (`follow`.`followerId`, `follow`.`followedId`)
        VALUE (userIdIN, followedUserId);
        
        SET result = 1;
    ELSE
    	SET result = 2;
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `generalRegistration` (IN `usernameIN` VARCHAR(50), IN `firstNameIN` VARCHAR(50), IN `lastNameIN` VARCHAR(50), IN `emailIN` VARCHAR(50), IN `birthdateIN` DATE, IN `passwordIN` VARCHAR(100))   BEGIN

	INSERT INTO `general` (`general`.`birthdate`)
	VALUES (birthdateIN);

	SELECT LAST_INSERT_ID() INTO @userId;
    
    INSERT INTO `user` (`user`.`username`, `user`.`email`, `user`.`password`, `user`.`rank`, `user`.`firstName`, `user`.`lastName`, `user`.`userId`)
    VALUES (usernameIN, emailIN, SHA1(passwordIN), "general", firstNameIN, lastNameIN, @userId);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getActiveHelpCenter` ()   SELECT `helpcenter`.`id`, `helpcenter`.`question`, `helpcenter`.`answer`
FROM `helpcenter`
WHERE `helpcenter`.`active` = 1$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllBooksByCategory` (IN `userIdIN` INT, IN `categoryIdIN` INT, IN `categoryNameIN` VARCHAR(50), OUT `result` INT, OUT `userRank` VARCHAR(20))   BEGIN

	DECLARE rank VARCHAR(20);

	IF (SELECT `category`.`name` FROM `category` WHERE `category`.`id` = categoryIdIN) != categoryNameIN THEN
    	
        SET result = 2;
    
    ELSE
    
    	SELECT `user`.`rank` INTO rank FROM `user` WHERE `user`.`id` = userIdIN;
        SET userRank = rank;

		IF rank = "general" THEN
            SELECT
                `book`.`id`,
                `book`.`coverImage`,
                `book`.`title`,
                `writer`.`firstName`,
                `writer`.`lastName`,
                `publisher`.`companyName`,
                `book`.`description`,
                `book`.`pagesNumber`,
                `bookrat`.`rat`,
                `language`.`code`,
                IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                `book`.`price`,
                `writer`.`username`,
                `category`.`name`,
                IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`,
                `publish`.`username` AS "publisher username"
            FROM `book`
            INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
            LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
            LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
            LEFT JOIN (
                SELECT `bookrating`.`bookId`,
                AVG(`bookrating`.`rating`) AS `rat`
                FROM `bookrating`
                GROUP BY `bookrating`.`bookId`
            ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
            INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
            LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
            INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
            LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
            WHERE `book`.`categoryId` = categoryIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by")
            ORDER BY RAND();
        ELSEIF rank = "publisher" THEN
        	SELECT
                `book`.`id`,
                `book`.`coverImage`,
                `book`.`title`,
                `writer`.`firstName`,
                `writer`.`lastName`,
                `publisher`.`companyName`,
                `book`.`description`,
                `book`.`pagesNumber`,
                `bookrat`.`rat`,
                `language`.`code`,
                IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                `book`.`price`,
                `writer`.`username`,
                `category`.`name`
            FROM `book`
            INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
            LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
            LEFT JOIN (
                SELECT `bookrating`.`bookId`,
                AVG(`bookrating`.`rating`) AS `rat`
                FROM `bookrating`
                GROUP BY `bookrating`.`bookId`
            ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
            INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
            LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
            INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
            WHERE `book`.`categoryId` = categoryIdIN AND `book`.`status` = "looking for a publisher"
            ORDER BY RAND();
        END IF;
        
        SET result = 1;
        
    END IF;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllCategory` ()   SELECT *
FROM `category`$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllLanguages` ()   SELECT *
FROM `language`$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllTargetAudiences` ()   SELECT *
FROM `targetaudience`$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getBookDetails` (IN `bookIdIN` INT)   SELECT
	`book`.`id`,
    `book`.`title`,
    `book`.`description`,
    `book`.`targetAudienceId`,
    `book`.`languageId`,
    `book`.`adultFiction`,
    `book`.`categoryId`,
    `book`.`status`,
    `book`.`price`,
    `book`.`coverImage`,
    `book`.`file`,
    `book`.`bankAccountNumber`,
    `book`.`chapterNumber`
FROM `book`
WHERE `book`.`id` = bookIdIN$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getDetails` (IN `userIdIN` INT)   BEGIN

	DECLARE rank VARCHAR(20);
    
    SELECT `user`.`rank` INTO rank FROM `user` WHERE `user`.`id` = userIdIN;
    
    IF rank = "general" THEN
    	SELECT
        	`user`.`rank`,
        	`user`.`username`,
            `user`.`email`,
            `user`.`phoneNumber`,
            `user`.`firstName`,
            `user`.`lastName`,
            `user`.`publicEmail`,
            `user`.`publicPhoneNumber`,
            `color`.`code`,
            `user`.`image`,
            `user`.`introDescription`,
            `user`.`website`
        FROM `user`
        INNER JOIN `color` ON `color`.`id` = `user`.`coverColorId`
        WHERE `user`.`id` = userIdIN;
    ELSEIF rank = "publisher" THEN
    	SELECT
        	`user`.`rank`,
        	`user`.`username`,
            `user`.`email`,
            `user`.`phoneNumber`,
            `user`.`firstName`,
            `user`.`lastName`,
            `user`.`publicEmail`,
            `user`.`publicPhoneNumber`,
            `color`.`code`,
            `user`.`image`,
            `user`.`introDescription`,
            `user`.`website`,
            `publisher`.`companyName`
        FROM `user`
        INNER JOIN `color` ON `color`.`id` = `user`.`coverColorId`
        INNER JOIN `publisher` ON `user`.`userId` = `publisher`.`id`
        WHERE `user`.`id` = userIdIN;
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getFeedPosts` (IN `userIdIN` INT)   SELECT 
	`post`.`id`,
    `user`.`username`, 
    `user`.`image`, 
    `post`.`postTime`, 
    `post`.`description`,
    IF(`postlike`.`userId` IS NOT NULL, TRUE, FALSE) AS `liked`
FROM 
    `user`
INNER JOIN 
    `follow` ON `follow`.`followedId` = `user`.`id`
INNER JOIN 
    `post` ON `post`.`userId` = `follow`.`followedId`
LEFT JOIN 
    `postlike` ON `postlike`.`postId` = `post`.`id` AND `postlike`.`userId` = userIdIN
WHERE
    `follow`.`followerId` = userIdIN
ORDER BY `post`.`postTime` DESC$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getFilteredBooks` (IN `userIdIN` INT, IN `filter` INT, IN `categoryIdIN` INT, OUT `result` INT, OUT `userRank` VARCHAR(20))   BEGIN

	DECLARE rank VARCHAR(20);

	IF NOT EXISTS(SELECT * FROM `category` WHERE `category`.`id` = categoryIdIN) THEN
    	SET result = 2;
    ELSEIF filter < 1 OR filter > 10 THEN
    	SET result = 3;
    ELSE

        SELECT `user`.`rank` INTO rank 
        FROM `user`
        WHERE `user`.`id` = userIdIN;
        SET userRank = rank;

        IF filter = 1 THEN
        	IF rank = "general" THEN
                SELECT
                    `book`.`id`,
                    `book`.`coverImage`,
                    `book`.`title`,
                    `writer`.`firstName`,
                    `writer`.`lastName`,
                    `publisher`.`companyName`,
                    `book`.`description`,
                    `book`.`pagesNumber`,
                    `bookrat`.`rat`,
                    `language`.`code`,
                    IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                    `book`.`price`,
                    `writer`.`username`,
                    `category`.`name`,
                    IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`,
                    `publish`.`username` AS "publisher username"
                FROM `book`
                INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                LEFT JOIN (
                    SELECT `bookrating`.`bookId`,
                    AVG(`bookrating`.`rating`) AS `rat`
                    FROM `bookrating`
                    GROUP BY `bookrating`.`bookId`
                ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
                WHERE `book`.`categoryId` = categoryIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by")
                ORDER BY `book`.`title` ASC;
            ELSEIF rank = "publisher" THEN
            	SELECT
                    `book`.`id`,
                    `book`.`coverImage`,
                    `book`.`title`,
                    `writer`.`firstName`,
                    `writer`.`lastName`,
                    `publisher`.`companyName`,
                    `book`.`description`,
                    `book`.`pagesNumber`,
                    `bookrat`.`rat`,
                    `language`.`code`,
                    IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                    `book`.`price`,
                    `writer`.`username`,
                    `category`.`name`
                FROM `book`
                INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                LEFT JOIN (
                    SELECT `bookrating`.`bookId`,
                    AVG(`bookrating`.`rating`) AS `rat`
                    FROM `bookrating`
                    GROUP BY `bookrating`.`bookId`
                ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                WHERE `book`.`categoryId` = categoryIdIN AND `book`.`status` = "looking for a publisher"
                ORDER BY `book`.`title` ASC;
            END IF;
        ELSEIF filter = 2 THEN
        	IF rank = "general" THEN
                SELECT
                    `book`.`id`,
                    `book`.`coverImage`,
                    `book`.`title`,
                    `writer`.`firstName`,
                    `writer`.`lastName`,
                    `publisher`.`companyName`,
                    `book`.`description`,
                    `book`.`pagesNumber`,
                    `bookrat`.`rat`,
                    `language`.`code`,
                    IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                    `book`.`price`,
                    `writer`.`username`,
                    `category`.`name`,
                    IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`,
                    `publish`.`username` AS "publisher username"
                FROM `book`
                INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                LEFT JOIN (
                    SELECT `bookrating`.`bookId`,
                    AVG(`bookrating`.`rating`) AS `rat`
                    FROM `bookrating`
                    GROUP BY `bookrating`.`bookId`
                ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
                WHERE `book`.`categoryId` = categoryIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by")
                ORDER BY `book`.`title` DESC;
            ELSEIF rank = "publisher" THEN
            	SELECT
                    `book`.`id`,
                    `book`.`coverImage`,
                    `book`.`title`,
                    `writer`.`firstName`,
                    `writer`.`lastName`,
                    `publisher`.`companyName`,
                    `book`.`description`,
                    `book`.`pagesNumber`,
                    `bookrat`.`rat`,
                    `language`.`code`,
                    IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                    `book`.`price`,
                    `writer`.`username`,
                    `category`.`name`
                FROM `book`
                INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                LEFT JOIN (
                    SELECT `bookrating`.`bookId`,
                    AVG(`bookrating`.`rating`) AS `rat`
                    FROM `bookrating`
                    GROUP BY `bookrating`.`bookId`
                ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                WHERE `book`.`categoryId` = categoryIdIN AND `book`.`status` = "looking for a publisher"
                ORDER BY `book`.`title` DESC;
            END IF;
        ELSEIF filter = 3 THEN
        	IF rank = "general" THEN
                SELECT
                    `book`.`id`,
                    `book`.`coverImage`,
                    `book`.`title`,
                    `writer`.`firstName`,
                    `writer`.`lastName`,
                    `publisher`.`companyName`,
                    `book`.`description`,
                    `book`.`pagesNumber`,
                    `bookrat`.`rat`,
                    `language`.`code`,
                    IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                    `book`.`price`,
                    `writer`.`username`,
                    `category`.`name`,
                    IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`,
                    `publish`.`username` AS "publisher username"
                FROM `book`
                INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                LEFT JOIN (
                    SELECT `bookrating`.`bookId`,
                    AVG(`bookrating`.`rating`) AS `rat`
                    FROM `bookrating`
                    GROUP BY `bookrating`.`bookId`
                ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
                WHERE `book`.`categoryId` = categoryIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by")
                ORDER BY `book`.`publishedTime` ASC;
            ELSEIF rank = "publisher" THEN
            	SELECT
                    `book`.`id`,
                    `book`.`coverImage`,
                    `book`.`title`,
                    `writer`.`firstName`,
                    `writer`.`lastName`,
                    `publisher`.`companyName`,
                    `book`.`description`,
                    `book`.`pagesNumber`,
                    `bookrat`.`rat`,
                    `language`.`code`,
                    IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                    `book`.`price`,
                    `writer`.`username`,
                    `category`.`name`
                FROM `book`
                INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                LEFT JOIN (
                    SELECT `bookrating`.`bookId`,
                    AVG(`bookrating`.`rating`) AS `rat`
                    FROM `bookrating`
                    GROUP BY `bookrating`.`bookId`
                ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                WHERE `book`.`categoryId` = categoryIdIN AND `book`.`status` = "looking for a publisher"
                ORDER BY `book`.`publishedTime` ASC;
            END IF;
        ELSEIF filter = 4 THEN
        	IF rank = "general" THEN
                SELECT
                    `book`.`id`,
                    `book`.`coverImage`,
                    `book`.`title`,
                    `writer`.`firstName`,
                    `writer`.`lastName`,
                    `publisher`.`companyName`,
                    `book`.`description`,
                    `book`.`pagesNumber`,
                    `bookrat`.`rat`,
                    `language`.`code`,
                    IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                    `book`.`price`,
                    `writer`.`username`,
                    `category`.`name`,
                    IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`,
                    `publish`.`username` AS "publisher username"
                FROM `book`
                INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                LEFT JOIN (
                    SELECT `bookrating`.`bookId`,
                    AVG(`bookrating`.`rating`) AS `rat`
                    FROM `bookrating`
                    GROUP BY `bookrating`.`bookId`
                ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
                WHERE `book`.`categoryId` = categoryIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by")
                ORDER BY `book`.`publishedTime` DESC;
            ELSEIF rank = "publisher" THEN
            	SELECT
                    `book`.`id`,
                    `book`.`coverImage`,
                    `book`.`title`,
                    `writer`.`firstName`,
                    `writer`.`lastName`,
                    `publisher`.`companyName`,
                    `book`.`description`,
                    `book`.`pagesNumber`,
                    `bookrat`.`rat`,
                    `language`.`code`,
                    IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                    `book`.`price`,
                    `writer`.`username`,
                    `category`.`name`
                FROM `book`
                INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                LEFT JOIN (
                    SELECT `bookrating`.`bookId`,
                    AVG(`bookrating`.`rating`) AS `rat`
                    FROM `bookrating`
                    GROUP BY `bookrating`.`bookId`
                ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                WHERE `book`.`categoryId` = categoryIdIN AND `book`.`status` = "looking for a publisher"
                ORDER BY `book`.`publishedTime` DESC;
            END IF;
        ELSE
            IF rank = "general" THEN
                IF filter = 5 THEN
                    SELECT
                        `book`.`id`,
                        `book`.`coverImage`,
                        `book`.`title`,
                        `writer`.`firstName`,
                        `writer`.`lastName`,
                        `publisher`.`companyName`,
                        `book`.`description`,
                        `book`.`pagesNumber`,
                        `bookrat`.`rat`,
                        `language`.`code`,
                        IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                        `book`.`price`,
                        `writer`.`username`,
                        `category`.`name`,
                        IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`,
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                    LEFT JOIN (
                        SELECT `bookrating`.`bookId`,
                        AVG(`bookrating`.`rating`) AS `rat`
                        FROM `bookrating`
                        GROUP BY `bookrating`.`bookId`
                    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                    LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                    LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
                    WHERE `book`.`categoryId` = categoryIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by")
                    ORDER BY `book`.`price` ASC;
                ELSEIF filter = 6 THEN
                    SELECT
                        `book`.`id`,
                        `book`.`coverImage`,
                        `book`.`title`,
                        `writer`.`firstName`,
                        `writer`.`lastName`,
                        `publisher`.`companyName`,
                        `book`.`description`,
                        `book`.`pagesNumber`,
                        `bookrat`.`rat`,
                        `language`.`code`,
                        IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                        `book`.`price`,
                        `writer`.`username`,
                        `category`.`name`,
                        IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`,
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                    LEFT JOIN (
                        SELECT `bookrating`.`bookId`,
                        AVG(`bookrating`.`rating`) AS `rat`
                        FROM `bookrating`
                        GROUP BY `bookrating`.`bookId`
                    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                    LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                    LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
                    WHERE `book`.`categoryId` = categoryIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by")
                    ORDER BY `book`.`price` DESC;
                ELSEIF filter = 7 THEN
                    SELECT
                        `book`.`id`,
                        `book`.`coverImage`,
                        `book`.`title`,
                        `writer`.`firstName`,
                        `writer`.`lastName`,
                        `publisher`.`companyName`,
                        `book`.`description`,
                        `book`.`pagesNumber`,
                        `bookrat`.`rat`,
                        `language`.`code`,
                        IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                        `book`.`price`,
                        `writer`.`username`,
                        `category`.`name`,
                        IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`,
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                    LEFT JOIN (
                        SELECT `bookrating`.`bookId`,
                        AVG(`bookrating`.`rating`) AS `rat`
                        FROM `bookrating`
                        GROUP BY `bookrating`.`bookId`
                    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                    LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                    LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
                    WHERE `book`.`categoryId` = categoryIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by")
                    ORDER BY (
                        SELECT COUNT(*)
                        FROM `saved`
                        WHERE `saved`.`bookId` = `book`.`id`
                    ) DESC;
                ELSEIF filter = 8 THEN
                    SELECT
                        `book`.`id`,
                        `book`.`coverImage`,
                        `book`.`title`,
                        `writer`.`firstName`,
                        `writer`.`lastName`,
                        `publisher`.`companyName`,
                        `book`.`description`,
                        `book`.`pagesNumber`,
                        `bookrat`.`rat`,
                        `language`.`code`,
                        IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                        `book`.`price`,
                        `writer`.`username`,
                        `category`.`name`,
                        IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`,
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                    LEFT JOIN (
                        SELECT `bookrating`.`bookId`,
                        AVG(`bookrating`.`rating`) AS `rat`
                        FROM `bookrating`
                        GROUP BY `bookrating`.`bookId`
                    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                    LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                    LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
                    WHERE `book`.`categoryId` = categoryIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by")
                    ORDER BY `bookrat`.`rat` ASC;
                ELSEIF filter = 9 THEN
                    SELECT
                        `book`.`id`,
                        `book`.`coverImage`,
                        `book`.`title`,
                        `writer`.`firstName`,
                        `writer`.`lastName`,
                        `publisher`.`companyName`,
                        `book`.`description`,
                        `book`.`pagesNumber`,
                        `bookrat`.`rat`,
                        `language`.`code`,
                        IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                        `book`.`price`,
                        `writer`.`username`,
                        `category`.`name`,
                        IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`,
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                    LEFT JOIN (
                        SELECT `bookrating`.`bookId`,
                        AVG(`bookrating`.`rating`) AS `rat`
                        FROM `bookrating`
                        GROUP BY `bookrating`.`bookId`
                    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                    LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                    LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
                    WHERE `book`.`categoryId` = categoryIdIN AND
                    `book`.`status` = "self-published";
                ELSEIF filter = 10 THEN
                    SELECT
                        `book`.`id`,
                        `book`.`coverImage`,
                        `book`.`title`,
                        `writer`.`firstName`,
                        `writer`.`lastName`,
                        `publisher`.`companyName`,
                        `book`.`description`,
                        `book`.`pagesNumber`,
                        `bookrat`.`rat`,
                        `language`.`code`,
                        IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                        `book`.`price`,
                        `writer`.`username`,
                        `category`.`name`,
                        IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`,
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                    LEFT JOIN (
                        SELECT `bookrating`.`bookId`,
                        AVG(`bookrating`.`rating`) AS `rat`
                        FROM `bookrating`
                        GROUP BY `bookrating`.`bookId`
                    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                    LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                    LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
                    WHERE `book`.`categoryId` = categoryIdIN AND
                    `book`.`status` = "published by";
                END IF;
            END IF;
        END IF;
        
        SET result = 1;
    
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getFilteredSavedBooks` (IN `userIdIN` INT, IN `filter` INT, OUT `result` INT, OUT `userRank` VARCHAR(20))   BEGIN

	DECLARE rank VARCHAR(20);

	IF filter < 1 OR filter > 10 THEN
    	SET result = 2;
    ELSE

        SELECT `user`.`rank` INTO rank 
        FROM `user`
        WHERE `user`.`id` = userIdIN;
        SET userRank = rank;

        IF filter = 1 THEN
        	IF rank = "general" THEN
                SELECT
                    `book`.`id`,
                    `book`.`coverImage`,
                    `book`.`title`,
                    `writer`.`firstName`,
                    `writer`.`lastName`,
                    `publisher`.`companyName`,
                    `book`.`description`,
                    `book`.`pagesNumber`,
                    `bookrat`.`rat`,
                    `language`.`code`,
                    IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                    `book`.`price`,
                    `writer`.`username`,
                    `category`.`name`,
                    IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`,
                    `publish`.`username` AS "publisher username"
                FROM `book`
                INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                LEFT JOIN (
                    SELECT `bookrating`.`bookId`,
                    AVG(`bookrating`.`rating`) AS `rat`
                    FROM `bookrating`
                    GROUP BY `bookrating`.`bookId`
                ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
                WHERE `saved`.`userId` = userIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by")
                ORDER BY `book`.`title` ASC;
            ELSEIF rank = "publisher" THEN
            	SELECT
                    `book`.`id`,
                    `book`.`coverImage`,
                    `book`.`title`,
                    `writer`.`firstName`,
                    `writer`.`lastName`,
                    `publisher`.`companyName`,
                    `book`.`description`,
                    `book`.`pagesNumber`,
                    `bookrat`.`rat`,
                    `language`.`code`,
                    IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                    `book`.`price`,
                    `writer`.`username`,
                    `category`.`name`
                FROM `book`
                INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                LEFT JOIN (
                    SELECT `bookrating`.`bookId`,
                    AVG(`bookrating`.`rating`) AS `rat`
                    FROM `bookrating`
                    GROUP BY `bookrating`.`bookId`
                ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                WHERE `saved`.`userId` = userIdIN AND `book`.`status` = "looking for a publisher"
                ORDER BY `book`.`title` ASC;
            END IF;
        ELSEIF filter = 2 THEN
        	IF rank = "general" THEN
                SELECT
                    `book`.`id`,
                    `book`.`coverImage`,
                    `book`.`title`,
                    `writer`.`firstName`,
                    `writer`.`lastName`,
                    `publisher`.`companyName`,
                    `book`.`description`,
                    `book`.`pagesNumber`,
                    `bookrat`.`rat`,
                    `language`.`code`,
                    IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                    `book`.`price`,
                    `writer`.`username`,
                    `category`.`name`,
                    IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`,
                    `publish`.`username` AS "publisher username"
                FROM `book`
                INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                LEFT JOIN (
                    SELECT `bookrating`.`bookId`,
                    AVG(`bookrating`.`rating`) AS `rat`
                    FROM `bookrating`
                    GROUP BY `bookrating`.`bookId`
                ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
                WHERE `saved`.`userId` = userIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by")
                ORDER BY `book`.`title` DESC;
            ELSEIF rank = "publisher" THEN
            	SELECT
                    `book`.`id`,
                    `book`.`coverImage`,
                    `book`.`title`,
                    `writer`.`firstName`,
                    `writer`.`lastName`,
                    `publisher`.`companyName`,
                    `book`.`description`,
                    `book`.`pagesNumber`,
                    `bookrat`.`rat`,
                    `language`.`code`,
                    IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                    `book`.`price`,
                    `writer`.`username`,
                    `category`.`name`
                FROM `book`
                INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                LEFT JOIN (
                    SELECT `bookrating`.`bookId`,
                    AVG(`bookrating`.`rating`) AS `rat`
                    FROM `bookrating`
                    GROUP BY `bookrating`.`bookId`
                ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                WHERE `saved`.`userId` = userIdIN AND `book`.`status` = "looking for a publisher"
                ORDER BY `book`.`title` DESC;
            END IF;
        ELSEIF filter = 3 THEN
        	IF rank = "general" THEN
                SELECT
                    `book`.`id`,
                    `book`.`coverImage`,
                    `book`.`title`,
                    `writer`.`firstName`,
                    `writer`.`lastName`,
                    `publisher`.`companyName`,
                    `book`.`description`,
                    `book`.`pagesNumber`,
                    `bookrat`.`rat`,
                    `language`.`code`,
                    IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                    `book`.`price`,
                    `writer`.`username`,
                    `category`.`name`,
                    IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`,
                    `publish`.`username` AS "publisher username"
                FROM `book`
                INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                LEFT JOIN (
                    SELECT `bookrating`.`bookId`,
                    AVG(`bookrating`.`rating`) AS `rat`
                    FROM `bookrating`
                    GROUP BY `bookrating`.`bookId`
                ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
                WHERE `saved`.`userId` = userIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by")
                ORDER BY `book`.`publishedTime` ASC;
            ELSEIF rank = "publisher" THEN
            	SELECT
                    `book`.`id`,
                    `book`.`coverImage`,
                    `book`.`title`,
                    `writer`.`firstName`,
                    `writer`.`lastName`,
                    `publisher`.`companyName`,
                    `book`.`description`,
                    `book`.`pagesNumber`,
                    `bookrat`.`rat`,
                    `language`.`code`,
                    IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                    `book`.`price`,
                    `writer`.`username`,
                    `category`.`name`
                FROM `book`
                INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                LEFT JOIN (
                    SELECT `bookrating`.`bookId`,
                    AVG(`bookrating`.`rating`) AS `rat`
                    FROM `bookrating`
                    GROUP BY `bookrating`.`bookId`
                ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                WHERE `saved`.`userId` = userIdIN AND `book`.`status` = "looking for a publisher"
                ORDER BY `book`.`publishedTime` ASC;
            END IF;
        ELSEIF filter = 4 THEN
        	IF rank = "general" THEN
                SELECT
                    `book`.`id`,
                    `book`.`coverImage`,
                    `book`.`title`,
                    `writer`.`firstName`,
                    `writer`.`lastName`,
                    `publisher`.`companyName`,
                    `book`.`description`,
                    `book`.`pagesNumber`,
                    `bookrat`.`rat`,
                    `language`.`code`,
                    IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                    `book`.`price`,
                    `writer`.`username`,
                    `category`.`name`,
                    IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`,
                    `publish`.`username` AS "publisher username"
                FROM `book`
                INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                LEFT JOIN (
                    SELECT `bookrating`.`bookId`,
                    AVG(`bookrating`.`rating`) AS `rat`
                    FROM `bookrating`
                    GROUP BY `bookrating`.`bookId`
                ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
                WHERE `saved`.`userId` = userIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by")
                ORDER BY `book`.`publishedTime` DESC;
            ELSEIF rank = "publisher" THEN
            	SELECT
                    `book`.`id`,
                    `book`.`coverImage`,
                    `book`.`title`,
                    `writer`.`firstName`,
                    `writer`.`lastName`,
                    `publisher`.`companyName`,
                    `book`.`description`,
                    `book`.`pagesNumber`,
                    `bookrat`.`rat`,
                    `language`.`code`,
                    IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                    `book`.`price`,
                    `writer`.`username`,
                    `category`.`name`
                FROM `book`
                INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                LEFT JOIN (
                    SELECT `bookrating`.`bookId`,
                    AVG(`bookrating`.`rating`) AS `rat`
                    FROM `bookrating`
                    GROUP BY `bookrating`.`bookId`
                ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                WHERE `saved`.`userId` = userIdIN AND `book`.`status` = "looking for a publisher"
                ORDER BY `book`.`publishedTime` DESC;
            END IF;
        ELSE
            IF rank = "general" THEN
                IF filter = 5 THEN
                    SELECT
                        `book`.`id`,
                        `book`.`coverImage`,
                        `book`.`title`,
                        `writer`.`firstName`,
                        `writer`.`lastName`,
                        `publisher`.`companyName`,
                        `book`.`description`,
                        `book`.`pagesNumber`,
                        `bookrat`.`rat`,
                        `language`.`code`,
                        IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                        `book`.`price`,
                        `writer`.`username`,
                        `category`.`name`,
                        IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`,
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                    LEFT JOIN (
                        SELECT `bookrating`.`bookId`,
                        AVG(`bookrating`.`rating`) AS `rat`
                        FROM `bookrating`
                        GROUP BY `bookrating`.`bookId`
                    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                    LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                    LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
                    WHERE `saved`.`userId` = userIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by")
                    ORDER BY `book`.`price` ASC;
                ELSEIF filter = 6 THEN
                    SELECT
                        `book`.`id`,
                        `book`.`coverImage`,
                        `book`.`title`,
                        `writer`.`firstName`,
                        `writer`.`lastName`,
                        `publisher`.`companyName`,
                        `book`.`description`,
                        `book`.`pagesNumber`,
                        `bookrat`.`rat`,
                        `language`.`code`,
                        IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                        `book`.`price`,
                        `writer`.`username`,
                        `category`.`name`,
                        IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`,
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                    LEFT JOIN (
                        SELECT `bookrating`.`bookId`,
                        AVG(`bookrating`.`rating`) AS `rat`
                        FROM `bookrating`
                        GROUP BY `bookrating`.`bookId`
                    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                    LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                    LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
                    WHERE `saved`.`userId` = userIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by")
                    ORDER BY `book`.`price` DESC;
                ELSEIF filter = 7 THEN
                    SELECT
                        `book`.`id`,
                        `book`.`coverImage`,
                        `book`.`title`,
                        `writer`.`firstName`,
                        `writer`.`lastName`,
                        `publisher`.`companyName`,
                        `book`.`description`,
                        `book`.`pagesNumber`,
                        `bookrat`.`rat`,
                        `language`.`code`,
                        IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                        `book`.`price`,
                        `writer`.`username`,
                        `category`.`name`,
                        IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`,
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                    LEFT JOIN (
                        SELECT `bookrating`.`bookId`,
                        AVG(`bookrating`.`rating`) AS `rat`
                        FROM `bookrating`
                        GROUP BY `bookrating`.`bookId`
                    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                    LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                    LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
                    WHERE `saved`.`userId` = userIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by")
                    ORDER BY (
                        SELECT COUNT(*)
                        FROM `saved`
                        WHERE `saved`.`bookId` = `book`.`id`
                    ) DESC;
                ELSEIF filter = 8 THEN
                    SELECT
                        `book`.`id`,
                        `book`.`coverImage`,
                        `book`.`title`,
                        `writer`.`firstName`,
                        `writer`.`lastName`,
                        `publisher`.`companyName`,
                        `book`.`description`,
                        `book`.`pagesNumber`,
                        `bookrat`.`rat`,
                        `language`.`code`,
                        IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                        `book`.`price`,
                        `writer`.`username`,
                        `category`.`name`,
                        IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`,
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                    LEFT JOIN (
                        SELECT `bookrating`.`bookId`,
                        AVG(`bookrating`.`rating`) AS `rat`
                        FROM `bookrating`
                        GROUP BY `bookrating`.`bookId`
                    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                    LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                    LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
                    WHERE `saved`.`userId` = userIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by")
                    ORDER BY `bookrat`.`rat` ASC;
                ELSEIF filter = 9 THEN
                    SELECT
                        `book`.`id`,
                        `book`.`coverImage`,
                        `book`.`title`,
                        `writer`.`firstName`,
                        `writer`.`lastName`,
                        `publisher`.`companyName`,
                        `book`.`description`,
                        `book`.`pagesNumber`,
                        `bookrat`.`rat`,
                        `language`.`code`,
                        IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                        `book`.`price`,
                        `writer`.`username`,
                        `category`.`name`,
                        IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`,
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                    LEFT JOIN (
                        SELECT `bookrating`.`bookId`,
                        AVG(`bookrating`.`rating`) AS `rat`
                        FROM `bookrating`
                        GROUP BY `bookrating`.`bookId`
                    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                    LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                    LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
                    WHERE `saved`.`userId` = userIdIN AND
                    `book`.`status` = "self-published";
                ELSEIF filter = 10 THEN
                    SELECT
                        `book`.`id`,
                        `book`.`coverImage`,
                        `book`.`title`,
                        `writer`.`firstName`,
                        `writer`.`lastName`,
                        `publisher`.`companyName`,
                        `book`.`description`,
                        `book`.`pagesNumber`,
                        `bookrat`.`rat`,
                        `language`.`code`,
                        IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                        `book`.`price`,
                        `writer`.`username`,
                        `category`.`name`,
                        IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`,
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
                    LEFT JOIN (
                        SELECT `bookrating`.`bookId`,
                        AVG(`bookrating`.`rating`) AS `rat`
                        FROM `bookrating`
                        GROUP BY `bookrating`.`bookId`
                    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                    LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                    LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
                    WHERE `saved`.`userId` = userIdIN AND
                    `book`.`status` = "published by";
                END IF;
            END IF;
        END IF;
        
        SET result = 1;
    
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getMostSavedBooksOfTheMonth` (IN `userIdIN` INT)   SELECT DISTINCT 
	`book`.`id`,
    `book`.`coverImage`,
	`book`.`title`, 
    `writer`.`username`, 
    `writer`.`firstName`, 
    `writer`.`lastName`,
    `publisher`.`companyName`,
    `book`.`description`,
    `book`.`pagesNumber`,
    `bookrat`.`rat`,
    `language`.`code`,
    IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
    `book`.`price`,
    `category`.`name`,
    IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`,
    `publish`.`username` AS "publisher username"
FROM `book`
INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
LEFT JOIN `publisher` ON `publisher`.`id` = `publish`.`userId`
LEFT JOIN (
    SELECT 
    	`bookrating`.`bookId`,
		AVG(`bookrating`.`rating`) AS `rat`
	FROM `bookrating`
	GROUP BY `bookrating`.`bookId`
) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
INNER JOIN (
    SELECT 
        `saved`.`bookId`, 
    	`saved`.`savedTime`,
        COUNT(`saved`.`id`) AS `count` 
    FROM `saved`
    GROUP BY `saved`.`bookId`
) AS `save` ON `book`.`id` = `save`.`bookId`
INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
WHERE 
	`saved`.`savedTime` >= NOW() - INTERVAL 30 DAY AND
    `book`.`writerId` != userIdIN AND
    `book`.`status` != "looking for a publisher"
ORDER BY `save`.`count` DESC
LIMIT 5$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getOneRandomBook` (IN `userIdIN` INT)   SELECT DISTINCT
    `book`.`id`, 
    `book`.`coverImage`, 
    `book`.`title`, 
    `writer`.`username`,
    `writer`.`firstName`,
    `writer`.`lastName`,
    `publisher`.`companyName`,
    `book`.`description`,
    `book`.`pagesNumber`,
    `bookrat`.`rat`,
    `language`.`code`, 
    IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
    `book`.`price`, 
    `category`.`name`,
    IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`,
    `publish`.`username` AS "publisher username"
FROM `book`
INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
LEFT JOIN `publisher` ON `publisher`.`id` = `publish`.`userId`
LEFT JOIN (
    SELECT `bookrating`.`bookId`,
	AVG(`bookrating`.`rating`) AS `rat`
	FROM `bookrating`
	GROUP BY `bookrating`.`bookId`
) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
WHERE `book`.`writerId` != userIdIN AND
`book`.`status` != "looking for a publisher"
ORDER BY RAND()
LIMIT 1$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getOneRandomLookingForPublisherBook` (IN `userIdIN` INT)   SELECT DISTINCT
    `book`.`id`, 
    `book`.`coverImage`, 
    `book`.`title`, 
    `writer`.`username`,
    `writer`.`firstName`,
    `writer`.`lastName`,
    `book`.`description`,
    `book`.`pagesNumber`,
    `bookrat`.`rat`,
    `language`.`code`, 
    IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
    `book`.`price`,
    `category`.`name`
FROM `book`
INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
LEFT JOIN (
    SELECT `bookrating`.`bookId`,
	AVG(`bookrating`.`rating`) AS `rat`
	FROM `bookrating`
	GROUP BY `bookrating`.`bookId`
) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
WHERE `book`.`status` = "looking for a publisher"
ORDER BY RAND()
LIMIT 1$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getPayedBooksByUserId` (IN `userIdIN` INT)   BEGIN


DECLARE rank VARCHAR(20);

SELECT `user`.`rank` INTO rank
FROM `user`
WHERE `user`.`id` = userIdIN;

IF rank = "general" THEN

    SELECT
        `book`.`id`,
        `book`.`coverImage`,
        `book`.`title`,
        `writer`.`firstName`,
        `writer`.`lastName`,
        `publisher`.`companyName`,
        `book`.`description`,
        `book`.`pagesNumber`,
        `bookrat`.`rat`,
        `language`.`code`,
        `writer`.`username`,
        `category`.`name`,
        `publish`.`username` AS "publisher username"
    FROM `book`
    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
    LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
    LEFT JOIN (
        SELECT `bookrating`.`bookId`,
        AVG(`bookrating`.`rating`) AS `rat`
        FROM `bookrating`
        GROUP BY `bookrating`.`bookId`
    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
    LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id`
    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
    WHERE `bookShopping`.`userId` = userIdIN;
    
END IF;


END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getPublishedBooks` (IN `userIdIN` INT)   SELECT DISTINCT
    `book`.`id`, 
    `book`.`coverImage`, 
    `book`.`title`, 
    `writer`.`username`,
    `writer`.`firstName`,
    `writer`.`lastName`,
    `publisher`.`companyName`,
    `book`.`description`,
    `book`.`pagesNumber`,
    `bookrat`.`rat`, 
    `language`.`code`, 
    IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
    `book`.`price`,
    `category`.`name`,
    IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`,
    `publish`.`username` AS "publisher username"
FROM `book`
INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
LEFT JOIN `publisher` ON `publisher`.`id` = `publish`.`userId`
LEFT JOIN (
    SELECT `bookrating`.`bookId`,
	AVG(`bookrating`.`rating`) AS `rat`
	FROM `bookrating`
	GROUP BY `bookrating`.`bookId`
) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
WHERE `book`.`status` = "published by" AND
`book`.`writerId` != userIdIN
ORDER BY RAND()
LIMIT 9$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getPublishedBooksByUserId` (IN `userIdIN` INT)   SELECT
    `book`.`id`,
    `book`.`coverImage`,
    `book`.`title`,
    `writer`.`firstName`,
    `writer`.`lastName`,
    `publisher`.`companyName`,
    `book`.`description`,
    `book`.`pagesNumber`,
    `bookrat`.`rat`,
    `language`.`code`,
    `book`.`price`,
    `writer`.`username`
FROM `book`
INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
LEFT JOIN (
    SELECT `bookrating`.`bookId`,
    AVG(`bookrating`.`rating`) AS `rat`
	FROM `bookrating`
    GROUP BY `bookrating`.`bookId`
) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id`
WHERE `book`.`publisherId` = userIdIN$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getPublishersWriters` (IN `pagesNumberIN` INT, IN `profileUsernameIN` VARCHAR(50))   BEGIN

	DECLARE rank VARCHAR(20);
    
    SELECT `user`.`rank` INTO rank FROM `user` WHERE `user`.`username` = profileUsernameIN;

	SET pagesNumberIN = pagesNumberIN - 1;

	IF rank = "publisher" THEN
        SELECT `user`.`image`, `user`.`username`
        FROM `user`
        WHERE `user`.`id` IN (
            SELECT `user`.`id`
            FROM `user`
            INNER JOIN `book` ON `book`.`writerId` = `user`.`id`
            WHERE `book`.`publisherId` = (
                SELECT `user`.`id`
                FROM `user`
                WHERE `user`.`username` = profileUsernameIN
            )
        )
        LIMIT 2 OFFSET pagesNumberIN;
    END IF;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getRandomBookByCategory` (IN `userIdIN` INT)   BEGIN

	DECLARE i INT DEFAULT 0;
    DECLARE cId INT;
    CREATE TEMPORARY TABLE IF NOT EXISTS RandomCategories (id INT);
    CREATE TEMPORARY TABLE IF NOT EXISTS result (
        id INT, 
        categoryName VARCHAR(50), 
        coverImage VARCHAR(100),
        title VARCHAR(50),
        username VARCHAR(50),
        firstName VARCHAR(50),
        lastName VARCHAR(50),
        description VARCHAR(1000),
        pagesNumber INT,
        rating DECIMAL(10, 2),
        languageCode CHAR(2),
        saved BOOLEAN,
        price INT
    );

	REPEAT
    	
    	SELECT `category`.`id` INTO cId
        FROM `category`
        WHERE EXISTS (
            SELECT `book`.`id`
            FROM `book`
            WHERE `book`.`categoryId` = `category`.`id` AND
			`book`.`status` = "looking for a publisher"
            LIMIT 1
        ) AND 
		`category`.`id` NOT IN (
        	SELECT id
            FROM RandomCategories
        )
        ORDER BY RAND()
        LIMIT 1;
              
        INSERT INTO result
        SELECT DISTINCT
            `book`.`id`, 
            `category`.`name`,
            `book`.`coverImage`, 
            `book`.`title`, 
            `writer`.`username`,
            `writer`.`firstName`,
            `writer`.`lastName`,
            `book`.`description`,
            `book`.`pagesNumber`,
            `bookrat`.`rat`, 
            `language`.`code`, 
            IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
            `book`.`price`
        FROM `book`
        LEFT JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
        LEFT JOIN (
            SELECT `bookrating`.`bookId`,
            AVG(`bookrating`.`rating`) AS `rat`
            FROM `bookrating`
            GROUP BY `bookrating`.`bookId`
        ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
        INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
        INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
        LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
        WHERE `book`.`status` = "looking for a publisher" AND
        `book`.`categoryId` = cId
        ORDER BY RAND()
        LIMIT 9;
        
        INSERT INTO RandomCategories (id)
        VALUES (cId);
                
        SET i = i + 1;
    UNTIL i = 4 END REPEAT;
    
    SELECT * FROM result;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getRecommandedBooks` (IN `userIdIN` INT)   SELECT DISTINCT
    `book`.`id`, 
    `book`.`coverImage`, 
    `book`.`title`,
    `writer`.`username`,
    `writer`.`firstName`,
    `writer`.`lastName`,
    `publisher`.`companyName`,
    `book`.`description`, 
    `book`.`pagesNumber`,
    `bookrat`.`rat`,
    `language`.`code`,
    IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
    `book`.`price`, 
    `category`.`name`,
    IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`,
    `publish`.`username` AS "publisher username"
FROM `book`
INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
LEFT JOIN `publisher` ON `publisher`.`id` = `publish`.`userId`
LEFT JOIN (
    SELECT `bookrating`.`bookId`,
	AVG(`bookrating`.`rating`) AS `rat`
	FROM `bookrating`
	GROUP BY `bookrating`.`bookId`
) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
WHERE (`book`.`categoryId` IN (
    SELECT `category`.`id`
	FROM `saved`
	INNER JOIN `book` ON `book`.`id` = `saved`.`bookId`
	INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
	WHERE `saved`.`userId` = userIdIN
)
OR
`book`.`categoryId` IN (
	SELECT `categoryinterest`.`categoryId`
    FROM `categoryinterest`
    WHERE `categoryinterest`.`userId` = userIdIN
)) AND
`book`.`writerId` != userIdIN AND
`book`.`status` != "looking for a publisher"
ORDER BY 
    RAND()
LIMIT 9$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getRecommandedBooksForPublisher` (IN `userIdIN` INT)   SELECT DISTINCT
    `book`.`id`, 
    `book`.`coverImage`, 
    `book`.`title`,
    `writer`.`username`,
    `writer`.`firstName`,
    `writer`.`lastName`,
    `book`.`description`, 
    `book`.`pagesNumber`,
    `bookrat`.`rat`,
    `language`.`code`,
    IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
    `book`.`price`,
    `category`.`name`
FROM `book`
INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
LEFT JOIN (
    SELECT `bookrating`.`bookId`,
	AVG(`bookrating`.`rating`) AS `rat`
	FROM `bookrating`
	GROUP BY `bookrating`.`bookId`
) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
WHERE (`book`.`categoryId` IN (
    SELECT `category`.`id`
	FROM `saved`
	INNER JOIN `book` ON `book`.`id` = `saved`.`bookId`
	INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
	WHERE `saved`.`userId` = userIdIN
)
OR
`book`.`categoryId` IN (
	SELECT `categoryinterest`.`categoryId`
    FROM `categoryinterest`
    WHERE `categoryinterest`.`userId` = userIdIN
)) AND
`book`.`status` = "looking for a publisher"
ORDER BY 
    RAND()
LIMIT 9$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getRecommandedUsers` (IN `userIdIN` INT)   SELECT DISTINCT `user`.`image`, `user`.`username`
FROM `user`
INNER JOIN `follow` ON `user`.`id` = `follow`.`followerId`
WHERE `follow`.`followedId` IN (
    SELECT DISTINCT `user`.`id`
	FROM `user`
	INNER JOIN `follow` ON `user`.`id` = `follow`.`followedId`
	WHERE `follow`.`followerId` = userIdIN
)
AND `user`.`id` != userIdIN
AND `user`.`id` NOT IN (
	SELECT `user`.`id`
    FROM `user`
    INNER JOIN `follow` ON `user`.`id` = `follow`.`followedId`
    WHERE `follow`.`followerId` = userIdIN
)
LIMIT 10$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getSavedBooksByCategoryId` (IN `userIdIN` INT, IN `categoryIdIN` INT, OUT `result` INT)   BEGIN
	
    IF EXISTS(SELECT * FROM `category` WHERE `category`.`id` = categoryIdIN) THEN
    
        SELECT
            `book`.`id`,
            `book`.`coverImage`,
            `book`.`title`,
            `writer`.`firstName`,
            `writer`.`lastName`,
            `publisher`.`companyName`,
            `book`.`description`,
            `book`.`pagesNumber`,
            `bookrat`.`rat`,
            `language`.`code`,
            `book`.`price`,
            `writer`.`username`
        FROM `book`
        INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
        LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
        LEFT JOIN (
            SELECT `bookrating`.`bookId`,
            AVG(`bookrating`.`rating`) AS `rat`
            FROM `bookrating`
            GROUP BY `bookrating`.`bookId`
        ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
        INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
        LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id`
        WHERE `saved`.`userId` = userIdIN AND `book`.`categoryId` = categoryIdIN;
        
        SET result = 1;
        
    ELSE
    	
        SET result = 2;
        
    END IF;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getSavedBooksByUserId` (IN `userIdIN` INT, OUT `userRank` VARCHAR(20))   BEGIN


DECLARE rank VARCHAR(20);

SELECT `user`.`rank` INTO rank FROM `user` WHERE `user`.`id` = userIdIN;
SET userRank = rank;

IF rank = "general" THEN
    SELECT
        `book`.`id`,
        `book`.`coverImage`,
        `book`.`title`,
        `writer`.`firstName`,
        `writer`.`lastName`,
        `publisher`.`companyName`,
        `book`.`description`,
        `book`.`pagesNumber`,
        `bookrat`.`rat`,
        `language`.`code`,
        `book`.`price`,
        `writer`.`username`,
        `category`.`name`,
        IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`,
        `publish`.`username` AS "publisher username"
    FROM `book`
    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
    LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
    LEFT JOIN (
        SELECT `bookrating`.`bookId`,
        AVG(`bookrating`.`rating`) AS `rat`
        FROM `bookrating`
        GROUP BY `bookrating`.`bookId`
    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
    LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id`
    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
    LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
    WHERE `saved`.`userId` = userIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by");
    
ELSEIF rank = "publisher" THEN

	SELECT
        `book`.`id`,
        `book`.`coverImage`,
        `book`.`title`,
        `writer`.`firstName`,
        `writer`.`lastName`,
        `publisher`.`companyName`,
        `book`.`description`,
        `book`.`pagesNumber`,
        `bookrat`.`rat`,
        `language`.`code`,
        `book`.`price`,
        `writer`.`username`,
        `category`.`name`
    FROM `book`
    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
    LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
    LEFT JOIN (
        SELECT `bookrating`.`bookId`,
        AVG(`bookrating`.`rating`) AS `rat`
        FROM `bookrating`
        GROUP BY `bookrating`.`bookId`
    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
    LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id`
    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
    WHERE `saved`.`userId` = userIdIN AND `book`.`status` = "looking for a publisher";

END IF;


END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getSearchBooks` (IN `userIdIN` INT, IN `searchTextIN` VARCHAR(50), OUT `rank` VARCHAR(20))   BEGIN

	DECLARE userRank VARCHAR(50);
    
    SELECT `user`.`rank` INTO userRank
    FROM `user`
    WHERE `user`.`id` = userIdIN;
    
    SET rank = userRank;
    
    IF userRank = "publisher" THEN
    	SELECT
            `book`.`id`,
            `book`.`coverImage`,
            `book`.`title`,
            `writer`.`firstName`,
            `writer`.`lastName`,
            `publisher`.`companyName`,
            `book`.`description`,
            `book`.`pagesNumber`,
            `bookrat`.`rat`,
            `language`.`code`,
            IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
            `book`.`price`,
            `writer`.`username`,
            `category`.`name`
        FROM `book`
        INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
        LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
        LEFT JOIN (
            SELECT `bookrating`.`bookId`,
            AVG(`bookrating`.`rating`) AS `rat`
            FROM `bookrating`
            GROUP BY `bookrating`.`bookId`
        ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
        INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
        LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
        INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
        WHERE (`book`.`title` LIKE CONCAT(searchTextIN, "%") OR `writer`.`firstName` LIKE CONCAT(searchTextIN, "%") OR `writer`.`lastName` LIKE CONCAT(searchTextIN, "%") OR `publisher`.`companyName` LIKE CONCAT(searchTextIN, "%")) AND `book`.`status` = "looking for a publisher";
    ELSEIF userRank = "general" THEN
    	SELECT
            `book`.`id`,
            `book`.`coverImage`,
            `book`.`title`,
            `writer`.`firstName`,
            `writer`.`lastName`,
            `publisher`.`companyName`,
            `book`.`description`,
            `book`.`pagesNumber`,
            `bookrat`.`rat`,
            `language`.`code`,
            IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
            `book`.`price`,
            `writer`.`username`,
            `category`.`name`,
            IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`,
            `publish`.`username` AS "publisher username"
        FROM `book`
        INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
        LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
        LEFT JOIN `publisher` ON `book`.`publisherId` = `publisher`.`id`
        LEFT JOIN (
            SELECT `bookrating`.`bookId`,
            AVG(`bookrating`.`rating`) AS `rat`
            FROM `bookrating`
            GROUP BY `bookrating`.`bookId`
        ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
        INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
        LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
        INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
        LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
        WHERE (`book`.`title` LIKE CONCAT(searchTextIN, "%") OR `writer`.`firstName` LIKE CONCAT(searchTextIN, "%") OR `writer`.`lastName` LIKE CONCAT(searchTextIN, "%") OR `publisher`.`companyName` LIKE CONCAT(searchTextIN, "%")) AND (`book`.`status` = "self-published" OR `book`.`status`= "published by");
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getSelfPublishedBooks` (IN `userIdIN` INT)   SELECT DISTINCT
    `book`.`id`, 
    `book`.`coverImage`, 
    `book`.`title`, 
    `writer`.`username`,
    `writer`.`firstName`,
    `writer`.`lastName`,
    `book`.`description`,
    `book`.`pagesNumber`,
   	`bookrat`.`rat`, 
    `language`.`code`,
    IF (`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
    `book`.`price`,
    `category`.`name`,
    IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`
FROM `book`
INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
LEFT JOIN (
    SELECT `bookrating`.`bookId`,
	AVG(`bookrating`.`rating`) AS `rat`
	FROM `bookrating`
	GROUP BY `bookrating`.`bookId`
) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
WHERE `book`.`status` = "self-published" AND
`book`.`writerId` != userIdIN
ORDER BY RAND()
LIMIT 9$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getUserBooks` (IN `userIdIN` INT, IN `profileUsernameIN` VARCHAR(50), OUT `result` INT, OUT `ownBooks` BOOLEAN, OUT `userRank` VARCHAR(20))   BEGIN

	DECLARE profileUserId INT;
    DECLARE profileUserRank VARCHAR(20);
    DECLARE rank VARCHAR(20);
    
    SELECT `user`.`rank` INTO rank
    FROM `user`
    WHERE `user`.`id` = userIdIN;
    
    SET userRank = rank;
    
    IF EXISTS (SELECT * FROM `user` WHERE `user`.`username` = profileUsernameIN) THEN
        SELECT `user`.`id` INTO profileUserId
        FROM `user`
        WHERE `user`.`username` = profileUsernameIN;
        
        SELECT `user`.`rank` INTO profileUserRank
        FROM `user`
        WHERE `user`.`id` = profileUserId;
        
        SET ownBooks = (profileUserId = userIdIN);
        
        SET result = 1;
        
        IF ownBooks = TRUE THEN
        
        	IF profileUserRank = "general" THEN
                SELECT
                    `book`.`id`,
                    `book`.`coverImage`,
                    `book`.`title`,
                    `user`.`username`,
                    `user`.`firstName`,
                    `user`.`lastName`,
                    `publisher`.`companyName`,
                    `book`.`description`,
                    `book`.`pagesNumber`,
                    `bookrat`.`rat`,
                    `language`.`code`,
                    IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                    `book`.`price`,
                    `category`.`name`
                FROM `book`
                INNER JOIN `user` ON `user`.`id` = `book`.`writerId`
                LEFT JOIN `publisher` ON `publisher`.`id` = `book`.`publisherId`
                INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                LEFT JOIN (
                    SELECT `bookrating`.`bookId`,
                    AVG(`bookrating`.`rating`) AS `rat`
                    FROM `bookrating`
                    GROUP BY `bookrating`.`bookId`
                ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                WHERE `book`.`writerId` = profileUserId
                ORDER BY `book`.`publishedTime` DESC;
            ELSEIF profileUserRank = "publisher" THEN
                SELECT
                    `book`.`id`,
                    `book`.`coverImage`,
                    `book`.`title`,
                    `user`.`username`,
                    `user`.`firstName`,
                    `user`.`lastName`,
                    `publisher`.`companyName`,
                    `book`.`description`,
                    `book`.`pagesNumber`,
                    `bookrat`.`rat`,
                    `language`.`code`,
                    IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                    `book`.`price`,
                    `category`.`name`
                FROM `book`
                INNER JOIN `user` ON `user`.`id` = `book`.`writerId`
                LEFT JOIN `publisher` ON `publisher`.`id` = `book`.`publisherId`
                INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                LEFT JOIN (
                    SELECT `bookrating`.`bookId`,
                    AVG(`bookrating`.`rating`) AS `rat`
                    FROM `bookrating`
                    GROUP BY `bookrating`.`bookId`
                ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                WHERE `book`.`publisherId` = profileUserId
            	ORDER BY `book`.`publishedTime` DESC;
            END IF;
        
        ELSE
        
            IF profileUserRank = "general" THEN
            	IF rank = "general" THEN
                    SELECT
                        `book`.`id`,
                        `book`.`coverImage`,
                        `book`.`title`,
                        `user`.`username`,
                        `user`.`firstName`,
                        `user`.`lastName`,
                        `publisher`.`companyName`,
                        `book`.`description`,
                        `book`.`pagesNumber`,
                        `bookrat`.`rat`,
                        `language`.`code`,
                        IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                        `book`.`price`,
                        `category`.`name`,
                        IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`
                    FROM `book`
                    INNER JOIN `user` ON `user`.`id` = `book`.`writerId`
                    LEFT JOIN `publisher` ON `publisher`.`id` = `book`.`publisherId`
                    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                    LEFT JOIN (
                        SELECT `bookrating`.`bookId`,
                        AVG(`bookrating`.`rating`) AS `rat`
                        FROM `bookrating`
                        GROUP BY `bookrating`.`bookId`
                    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                    LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                    LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
                    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                    WHERE `book`.`writerId` = profileUserId AND `book`.`status` != "looking for a publisher"
                    ORDER BY `book`.`publishedTime` DESC;
                ELSEIF rank = "publisher" THEN
                	SELECT
                        `book`.`id`,
                        `book`.`coverImage`,
                        `book`.`title`,
                        `user`.`username`,
                        `user`.`firstName`,
                        `user`.`lastName`,
                        `publisher`.`companyName`,
                        `book`.`description`,
                        `book`.`pagesNumber`,
                        `bookrat`.`rat`,
                        `language`.`code`,
                        IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                        `book`.`price`,
                        `category`.`name`
                    FROM `book`
                    INNER JOIN `user` ON `user`.`id` = `book`.`writerId`
                    LEFT JOIN `publisher` ON `publisher`.`id` = `book`.`publisherId`
                    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                    LEFT JOIN (
                        SELECT `bookrating`.`bookId`,
                        AVG(`bookrating`.`rating`) AS `rat`
                        FROM `bookrating`
                        GROUP BY `bookrating`.`bookId`
                    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                    LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                    WHERE `book`.`writerId` = profileUserId AND `book`.`status` = "looking for a publisher"
                    ORDER BY `book`.`publishedTime` DESC;
                END IF;
            ELSEIF profileUserRank = "publisher" THEN
            	IF rank = "general" THEN
                    SELECT
                        `book`.`id`,
                        `book`.`coverImage`,
                        `book`.`title`,
                        `user`.`username`,
                        `user`.`firstName`,
                        `user`.`lastName`,
                        `publisher`.`companyName`,
                        `book`.`description`,
                        `book`.`pagesNumber`,
                        `bookrat`.`rat`,
                        `language`.`code`,
                        IF(`saved`.`userId` IS NOT NULL, TRUE, FALSE) AS `save`,
                        `book`.`price`,
                        `category`.`name`,
                        IF(`bookShopping`.`userId` IS NOT NULL, TRUE, FALSE) AS `purchased`
                    FROM `book`
                    INNER JOIN `user` ON `user`.`id` = `book`.`writerId`
                    LEFT JOIN `publisher` ON `publisher`.`id` = `book`.`publisherId`
                    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                    LEFT JOIN (
                        SELECT `bookrating`.`bookId`,
                        AVG(`bookrating`.`rating`) AS `rat`
                        FROM `bookrating`
                        GROUP BY `bookrating`.`bookId`
                    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                    LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                    LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id` AND `bookShopping`.`userId` = userIdIN
                    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                    WHERE `book`.`publisherId` = profileUserId
                    ORDER BY `book`.`publishedTime` DESC;
                ELSEIF rank = "publisher" THEN
                	SET result = 3;
                END IF;
            END IF;
            
        END IF;
        
    ELSE
    	SET result = 2;
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getUserDetails` (IN `userIdIN` INT, IN `usernameIN` VARCHAR(50), IN `profileUsernameIN` VARCHAR(50), OUT `result` INT)   BEGIN
    DECLARE profileUserId INT;
    DECLARE profileUserRank VARCHAR(20);
    DECLARE userIdMatch BOOLEAN;

    IF EXISTS (SELECT * FROM `user` WHERE `user`.`username` = profileUsernameIN) THEN
        SELECT `user`.`id` INTO profileUserId
        FROM `user`
        WHERE `user`.`username` = profileUsernameIN;
        
        SELECT `user`.`rank` INTO profileUserRank
        FROM `user`
        WHERE `user`.`id` = profileUserId;
        
        SET userIdMatch = (profileUserId = userIdIN);
        
        IF profileUserRank = "general" THEN
            SELECT
                `user`.`rank`,
                `user`.`username`,
                `user`.`image`,
                IF(`follow`.`followerId` IS NOT NULL, TRUE, FALSE) AS `followed`,
                `user`.`firstName`,
                `user`.`lastName`,
                (SELECT COUNT(`book`.`id`) FROM `book` WHERE `book`.`writerId` = profileUserId) AS bookCount,
                (SELECT COUNT(`saved`.`id`) FROM `saved` WHERE `saved`.`userId` = profileUserId) AS savedCount,
                (SELECT COUNT(`follow`.`id`) FROM `follow` WHERE `follow`.`followedId` = profileUserId) AS followCount,
                `user`.`introDescription`,
                `user`.`website`,
                `color`.`code`,
                userIdMatch AS userIdMatchFlag,
                IF((SELECT `user`.`publicEmail` FROM `user` WHERE `user`.`id` = profileUserId) = TRUE, (SELECT `user`.`email` FROM `user` WHERE `user`.`id` = profileUserId), NULL) AS email,
                IF((SELECT `user`.`publicPhoneNumber` FROM `user` WHERE `user`.`id` = profileUserId) = TRUE, (SELECT `user`.`phoneNumber` FROM `user` WHERE `user`.`id` = profileUserId), NULL) AS phoneNumber,
            	YEAR(`user`.`registrationTime`)
            FROM `user`
            LEFT JOIN `follow` ON `follow`.`followedId` = profileUserId AND `follow`.`followerId` = userIdIN
            INNER JOIN `color` ON `color`.`id` = `user`.`coverColorId`
            WHERE `user`.`id` = profileUserId;
        ELSEIF profileUserRank = "publisher" THEN
            SELECT
                `user`.`rank`,
                `user`.`username`,
                `user`.`image`,
                IF(`follow`.`followerId` IS NOT NULL, TRUE, FALSE) AS `followed`,
                `publisher`.`companyName`,
                (SELECT COUNT(`book`.`id`) FROM `book` WHERE `book`.`publisherId` = profileUserId) AS bookCount,
                (SELECT COUNT(`writers`.`writerId`) FROM (SELECT DISTINCT `book`.`writerId` FROM `book` WHERE `book`.`publisherId` = profileUserId) AS `writers`) AS writerCount,
                (SELECT COUNT(`follow`.`id`) FROM `follow` WHERE `follow`.`followedId` = profileUserId) AS followCount,
                `user`.`introDescription`,
                `user`.`website`,
                `color`.`code`,
                userIdMatch AS userIdMatchFlag,
                IF((SELECT `user`.`publicEmail` FROM `user` WHERE `user`.`id` = profileUserId) = TRUE, (SELECT `user`.`email` FROM `user` WHERE `user`.`id` = profileUserId), NULL) AS email,
                IF((SELECT `user`.`publicPhoneNumber` FROM `user` WHERE `user`.`id` = profileUserId) = TRUE, (SELECT `user`.`phoneNumber` FROM `user` WHERE `user`.`id` = profileUserId), NULL) AS phoneNumber,
                YEAR(`user`.`registrationTime`)
            FROM `user`
            LEFT JOIN `follow` ON `follow`.`followedId` = profileUserId AND `follow`.`followerId` = userIdIN
            INNER JOIN `color` ON `color`.`id` = `user`.`coverColorId`
            INNER JOIN `publisher` ON `publisher`.`id` = `user`.`userId`
            WHERE `user`.`id` = profileUserId;
        END IF;
        
        SET result = 1;
    ELSE
        SET result = 2;
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getUserPosts` (IN `userIdIN` INT, IN `profileUsernameIN` VARCHAR(50), OUT `result` INT, OUT `ownPosts` BOOLEAN)   BEGIN

	DECLARE profileUserId INT;
    
    IF EXISTS (SELECT * FROM `user` WHERE `user`.`username` = profileUsernameIN) THEN
        SELECT `user`.`id` INTO profileUserId
        FROM `user`
        WHERE `user`.`username` = profileUsernameIN;
        
        SET ownPosts = (profileUserId = userIdIN);
        
        SELECT
          	`post`.`id`,
            `user`.`username`,
            `user`.`image`,
            `post`.`postTime`,
            `post`.`description`,
            IF(`postlike`.`userId` IS NOT NULL, TRUE, FALSE) AS `liked`
        FROM `post`
        INNER JOIN `user` ON `user`.`id` = `post`.`userId`
        LEFT JOIN `postlike` ON `postlike`.`postId` = `post`.`id` AND `postlike`.`userId` = userIdIN
        WHERE `user`.`id` = profileUserId
        ORDER BY `post`.`postTime` DESC;
        
        SET result = 1;
    ELSE
    	SET result = 2;
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `login` (IN `emailIN` VARCHAR(50), IN `passwordIN` VARCHAR(100), OUT `userIdOUT` INT, OUT `usernameOUT` VARCHAR(50), OUT `firstNameOUT` VARCHAR(50), OUT `lastNameOUT` VARCHAR(50), OUT `imageOUT` VARCHAR(100), OUT `rankOUT` ENUM("admin","general","publisher"), OUT `activeOUT` BOOLEAN)   BEGIN

	SELECT `user`.`id`, `user`.`username`, `user`.`firstName`, `user`.`lastName`, `user`.`image`, `user`.`rank`, `user`.`firstLogin`
	INTO userIdOUT, usernameOUT, firstNameOUT, lastNameOUT, imageOUT, rankOUT, activeOUT
	FROM `user`
	WHERE `user`.`email` = emailIN AND `user`.`password` = SHA1(passwordIN);
    
    UPDATE `user`
    SET `user`.`firstLogin` = false
    WHERE `user`.`email` = emailIN;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `postDislike` (IN `userIdIN` INT, IN `postIdIN` INT, OUT `result` INT)   BEGIN

	IF NOT EXISTS (SELECT * FROM `post` WHERE `post`.`id` = postIdIN) THEN
        SET result = 2;
    ELSE
        DELETE 
        FROM `postlike`
        WHERE `postlike`.`userId` = userIdIN AND `postlike`.`postId` = postIdIN;

        SET result = 1;
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `postLike` (IN `userIdIN` INT, IN `postIdIN` INT, OUT `result` INT)   BEGIN

	IF NOT EXISTS (SELECT * FROM `post` WHERE `post`.`id` = postIdIN) THEN
    	SET result = 2;
    ELSE
        INSERT INTO `postlike` (`postlike`.`userId`, `postlike`.`postId`)
        VALUES (userIdIN, postIdIN);
        
        SET result = 1;
    END IF;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `publisherRegistration` (IN `usernameIN` VARCHAR(50), IN `firstNameIN` VARCHAR(50), IN `lastNameIN` VARCHAR(50), IN `companyNameIN` VARCHAR(50), IN `emailIN` VARCHAR(50), IN `passwordIN` VARCHAR(100))   BEGIN

	INSERT INTO `publisher` (`publisher`.`companyName`)
	VALUES (companyNameIN);

	SELECT LAST_INSERT_ID() INTO @userId;
    
    INSERT INTO `user` (`user`.`username`, `user`.`email`, `user`.`password`, `user`.`rank`, `user`.`firstName`, `user`.`lastName`, `user`.`userId`)
    VALUES (usernameIN, emailIN, SHA1(passwordIN), "publisher", firstNameIN, lastNameIN, @userId);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `saveBook` (IN `userIdIN` INT, IN `bookIdIN` INT, OUT `result` INT)   BEGIN

	IF NOT EXISTS (SELECT * FROM `saved` WHERE `saved`.`userId` = userIdIN AND `saved`.`bookId` = bookIdIN) THEN

        INSERT INTO `saved` (`saved`.`userId`, `saved`.`bookId`)
        VALUE (userIdIN, bookIdIN);
        
        SET result = 1;
        
    ELSE
    	
        SET result = 2;
        
    END IF;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `setBook` (IN `bookIdIN` INT, IN `titleIN` VARCHAR(50), IN `descriptionIN` VARCHAR(1000), IN `targetAudienceIdIN` INT, IN `languageIdIN` INT, IN `adultFictionIN` BOOLEAN, IN `categoryIdIN` INT, IN `statusIdIN` INT, IN `priceIN` INT, IN `coverImageIN` VARCHAR(100), IN `fileIN` VARCHAR(100), IN `bankAccountNumberIN` VARCHAR(30), IN `chapterNumberIN` INT, IN `freeChapterNumberIN` INT, OUT `result` INT)   BEGIN

	DECLARE userId INT;
    
    SELECt `book`.`writerId` INTO userId FROM `book` WHERE `book`.`id` = bookIdIN;
    
    IF NOT EXISTS (SELECT * FROM `targetaudience` WHERE `targetaudience`.`id` = targetAudienceIdIN) AND NOT EXISTS (SELECT * FROM `language` WHERE `language`.`id` = languageIdIN) AND NOT EXISTS (SELECT * FROM `category` WHERE `category`.`id` = categoryIdIN) THEN
    	SET result = 8;
    ELSEIF NOT EXISTS (SELECT * FROM `language` WHERE `language`.`id` = languageIdIN) AND NOT EXISTS (SELECT * FROM `category` WHERE `category`.`id` = categoryIdIN) THEN
    	SET result = 7;

    ELSEIF NOT EXISTS (SELECT * FROM `targetaudience` WHERE `targetaudience`.`id` = targetAudienceIdIN) AND NOT EXISTS (SELECT * FROM `category` WHERE `category`.`id` = categoryIdIN) THEN
    	SET result = 6;
    ELSEIF NOT EXISTS (SELECT * FROM `targetaudience` WHERE `targetaudience`.`id` = targetAudienceIdIN) AND NOT EXISTS (SELECT * FROM `language` WHERE `language`.`id` = languageIdIN) THEN
    	SET result = 5;
    ELSEIF NOT EXISTS (SELECT * FROM `category` WHERE `category`.`id` = categoryIdIN) THEN
    	SET result = 4;
    ELSEIF NOT EXISTS (SELECT * FROM `language` WHERE `language`.`id` = languageIdIN) THEN
    	SET result = 3;
    ELSEIF NOT EXISTS (SELECT * FROM `targetaudience` WHERE `targetaudience`.`id` = targetAudienceIdIN) THEN
    	SET result = 2;
    ELSE
    
        IF statusIdIN IS NOT NULL THEN
            IF statusIdIN = 1 THEN
                UPDATE `book`
                SET `book`.`status` = "looking for a publisher"
                WHERE `book`.`id` = bookIdIN;

                UPDATE `book`
                SET `book`.`price` = NULL
                WHERE `book`.`id` = bookIdIN;
            ELSEIF statusIdIN = 2 THEN
                UPDATE `book`
                SET `book`.`status` = "self-published"
                WHERE `book`.`id` = bookIdIN;

                IF priceIN IS NOT NULL THEN
                    UPDATE `book`
                    SET `book`.`price` = priceIN
                    WHERE `book`.`id` = bookIdIN;
                END IF;

                IF bankAccountNumberIN IS NOT NULL THEN
                    UPDATE `book`
                    SET `book`.`bankAccountNumber` = bankAccountNumberIN
                    WHERE `book`.`id` = bookIdIN;
                 END IF;
            END IF;
        END IF;

        IF titleIN IS NOT NULL THEN
            UPDATE `book`
            SET `book`.`title` = titleIN
            WHERE `book`.`id` = bookIdIN;
        END IF;

        IF descriptionIN IS NOT NULL THEN
            UPDATE `book`
            SET `book`.`description` = descriptionIN
            WHERE `book`.`id` = bookIdIN;
        END IF;

        IF targetAudienceIdIN IS NOT NULL THEN
            UPDATE `book`
            SET `book`.`targetAudienceId` = targetAudienceIdIN
            WHERE `book`.`id` = bookIdIN;
        END IF;

        IF languageIdIN IS NOT NULL THEN
            UPDATE `book`
            SET `book`.`languageId` = languageIdIN
            WHERE `book`.`id` = bookIdIN;
        END IF;

        IF adultFictionIN IS NOT NULL THEN
            UPDATE `book`
            SET `book`.`adultFiction` = adultFictionIN
            WHERE `book`.`id` = bookIdIN;
        END IF;

        IF categoryIdIN IS NOT NULL THEN
            UPDATE `book`
            SET `book`.`categoryId` = categoryIdIN
            WHERE `book`.`id` = bookIdIN;
        END IF;

        IF coverImageIN IS NOT NULL THEN
            UPDATE `book`
            SET `book`.`coverImage` = coverImageIN
            WHERE `book`.`id` = bookIdIN;
        END IF;

        IF fileIN IS NOT NULL THEN
            UPDATE `book`
            SET `book`.`file` = fileIN
            WHERE `book`.`id` = bookIdIN;
        END IF;
        
        IF chapterNumberIN IS NOT NULL THEN
            UPDATE `book`
            SET `book`.`chapterNumber` = chapterNumberIN
            WHERE `book`.`id` = bookIdIN;
        END IF;
        
        IF freeChapterNumberIN IS NOT NULL THEN
            UPDATE `book`
            SET `book`.`freeChapterNumber` = freeChapterNumberIN
            WHERE `book`.`id` = bookIdIN;
        END IF;

        SET result = 1;
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `setCompanyName` (IN `userIdIN` INT, IN `companyNameIN` VARCHAR(50), OUT `result` INT)   BEGIN

	DECLARE rank VARCHAR(20);
    
    SELECT `user`.`rank` INTO rank FROM `user` WHERE `user`.`id` = userIdIN;
    
    IF rank = "publisher" THEN
    	UPDATE `publisher`
        SET `publisher`.`companyName` = companyNameIN
        WHERE `publisher`.`id` = (SELECT `user`.`userId` FROM `user` WHERE `user`.`id` = userIdIN);
    
    	SET result = 1;
    ELSE
    	SET result = 2;
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `setCoverColor` (IN `userIdIN` INT, IN `coverColorIN` VARCHAR(8))   BEGIN

	DECLARE colorId INT;

	IF CHAR_LENGTH(coverColorIN) = 0 THEN
    	SET colorId = 1;
	ELSEIF EXISTS(SELECT * FROM `color` WHERE `color`.`code` = coverColorIN) THEN
    	SELECT `color`.`id` INTO colorId FROM `color` WHERE `color`.`code` = coverColorIN;
    ELSE
    	INSERT INTO `color` (`color`.`code`)
        VALUES (coverColorIN);
        
        SELECT LAST_INSERT_ID() INTO colorId;
    END IF;
    
    UPDATE `user`
    SET `user`.`coverColorId` = colorId
    WHERE `user`.`id` = userIdIN;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `setEmail` (IN `userIdIN` INT, IN `emailIN` VARCHAR(50))   UPDATE `user`
SET `user`.`email` = emailIN
WHERE `user`.`id` = userIdIN$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `setFirstName` (IN `userIdIN` INT, IN `firstNameIN` VARCHAR(50))   UPDATE `user`
SET `user`.`firstName` = firstNameIN
WHERE `user`.`id` = userIdIN$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `setIntroDescription` (IN `userIdIN` INT, IN `introDescriptionIN` VARCHAR(1000))   UPDATE `user`
SET `user`.`introDescription` = introDescriptionIN
WHERE `user`.`id` = userIdIN$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `setLastName` (IN `userIdIN` INT, IN `lastNameIN` VARCHAR(50))   UPDATE `user`
SET `user`.`lastName` = lastNameIN
WHERE `user`.`id` = userIdIN$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `setPassword` (IN `userIdIN` INT, IN `passwordIN` VARCHAR(100), OUT `result` INT)   BEGIN

	IF SHA1(passwordIN) = (SELECT `user`.`password` FROM `user` WHERE `user`.`id` = userIdIN) THEN
    	SET result = 2;
    ELSE
        UPDATE `user`
        SET `user`.`password` = SHA1(passwordIN)
        WHERE `user`.`id` = userIdIN;
        
        SET result = 1;
    END IF;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `setPhoneNumber` (IN `userIdIN` INT, IN `phoneNumberIN` VARCHAR(15))   UPDATE `user`
SET `user`.`phoneNumber` = phoneNumberIN
WHERE `user`.`id` = userIdIN$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `setProfileImage` (IN `userIdIN` INT, IN `imageIN` VARCHAR(100))   BEGIN

	IF CHAR_LENGTH(imageIN) = 0 THEN
        UPDATE `user`
        SET `user`.`image` = "pictures/default-profile-pic-man.png"
        WHERE `user`.`id` = userIdIN;
    ELSE
        UPDATE `user`
        SET `user`.`image` = imageIN
        WHERE `user`.`id` = userIdIN;
    END IF;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `setPublicEmail` (IN `userIdIN` INT)   BEGIN

	IF (SELECT `user`.`publicEmail` FROM `user` WHERE `user`.`id` = userIdIN) = true THEN
    	UPDATE `user`
        SET `user`.`publicEmail` = false
        WHERE `user`.`id` = userIdIN;
    ELSE
    	UPDATE `user`
        SET `user`.`publicEmail` = true
        WHERE `user`.`id` = userIdIN;
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `setPublicPhoneNumber` (IN `userIdIN` INT)   BEGIN

	IF (SELECT `user`.`publicPhoneNumber` FROM `user` WHERE `user`.`id` = userIdIN) = false THEN
    	UPDATE `user`
        SET `user`.`publicPhoneNumber` = true
        WHERE `user`.`id` = userIdIN;
    ELSE
    	UPDATE `user`
        SET `user`.`publicPhoneNumber` = false
        WHERE `user`.`id` = userIdIN;
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `setUsername` (IN `userIdIN` INT, IN `usernameIN` VARCHAR(50))   UPDATE `user`
SET `user`.`username` = usernameIN
WHERE `user`.`id` = userIdIN$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `setWebsite` (IN `userIdIN` INT, IN `websiteIN` VARCHAR(100))   UPDATE `user`
SET `user`.`website` = websiteIN
WHERE `user`.`id` = userIdIN$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `unfollowedUser` (IN `userIdIN` INT, IN `followedUsernameIN` VARCHAR(50), OUT `result` INT)   BEGIN

	DECLARE followedUserId INT;
    
    SELECT `user`.`id` INTO followedUserId FROM `user` WHERE `user`.`username` = followedUsernameIN;

	IF EXISTS (SELECT * FROM `follow` WHERE `follow`.`followerId` = userIdIN AND `follow`.`followedId` = followedUserId) THEN
    	DELETE FROM `follow`
        WHERE `follow`.`followerId` = userIdIN AND `follow`.`followedId` = followedUserId;
    	
        SET result = 1;
    ELSE
    	SET result = 2;
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updatePost` (IN `userIdIN` INT, IN `postIdIN` INT, IN `postDescriptionIN` VARCHAR(1000), OUT `result` INT)   BEGIN

	IF (SELECT `post`.`userId` FROM `post` WHERE `post`.`id` = postIdIN) != userIdIN THEN
    	SET result = 3;
    ELSEIF EXISTS (SELECT * FROM `post` WHERE `post`.`id` = postIdIN AND `post`.`userId` = userIdIN) THEN
    	UPDATE `post`
        SET `post`.`description` = postDescriptionIN, `post`.`postTime` = CURRENT_TIMESTAMP()
        WHERE `post`.`id` = postIdIN;
        
        SET result = 1;
    ELSE
    	SET result = 2;
    END IF;

END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `aszf`
--

CREATE TABLE `aszf` (
  `id` int(11) NOT NULL,
  `startDate` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `endDate` timestamp NULL DEFAULT NULL,
  `file` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `book`
--

CREATE TABLE `book` (
  `id` int(11) NOT NULL,
  `title` varchar(50) NOT NULL,
  `status` enum('looking for a publisher','published by','self-published') NOT NULL,
  `writerId` int(11) NOT NULL,
  `publisherId` int(11) DEFAULT NULL,
  `publishedTime` timestamp NOT NULL DEFAULT current_timestamp(),
  `description` varchar(1000) NOT NULL,
  `price` int(10) UNSIGNED DEFAULT NULL,
  `coverImage` varchar(100) NOT NULL,
  `file` varchar(100) NOT NULL,
  `chapterNumber` int(10) UNSIGNED NOT NULL,
  `freeChapterNumber` int(10) UNSIGNED NOT NULL,
  `pagesNumber` int(10) UNSIGNED NOT NULL,
  `adultFiction` tinyint(1) NOT NULL,
  `bankAccountNumber` varchar(30) DEFAULT NULL,
  `languageId` int(11) NOT NULL,
  `targetAudienceId` int(11) NOT NULL,
  `categoryId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `bookrating`
--

CREATE TABLE `bookrating` (
  `id` int(11) NOT NULL,
  `ratingerId` int(11) NOT NULL,
  `bookId` int(11) NOT NULL,
  `rating` int(10) UNSIGNED NOT NULL,
  `ratingTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `bookreport`
--

CREATE TABLE `bookreport` (
  `id` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `bookId` int(11) NOT NULL,
  `description` varchar(500) NOT NULL,
  `reportTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `bookshopping`
--

CREATE TABLE `bookshopping` (
  `id` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `bookId` int(11) NOT NULL,
  `shoppingTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `category`
--

CREATE TABLE `category` (
  `id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  `image` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- A tábla adatainak kiíratása `category`
--

INSERT INTO `category` (`id`, `name`, `image`) VALUES
(1, 'Literature', 'pictures/category/fine-literature.jpg'),
(2, 'Gastronomy', 'pictures/category/gastronomy.jpg'),
(3, 'Social Sciences', 'pictures/category/social-siences.jpg'),
(4, 'Lifestyle and Health', 'pictures/category/lifestyle_health.jpg'),
(5, 'Dictionary', 'pictures/category/language_dictionaries.jpg'),
(6, 'Youth novels', 'pictures/category/children_young-adult.jpg'),
(7, 'Lexicons', 'pictures/category/lexicon_encyclopedia.jpg'),
(8, 'Sport', 'pictures/category/sports.jpg'),
(9, 'Comic Book', 'pictures/category/comics.jpg'),
(10, 'Biography', 'pictures/category/biographies.jpg'),
(11, 'Textbooks, Study Guides', 'pictures/category/textbook_study-guides.jpg'),
(12, 'Art & architecture', 'pictures/category/arts_architectures.jpg'),
(13, 'Novel', 'pictures/category/novel.jpg'),
(14, 'Maps', 'pictures/category/maps.jpg'),
(15, 'Travel', 'pictures/category/travel.jpg'),
(16, 'Religion', 'pictures/category/religion.jpg'),
(17, 'Educational', 'pictures/category/educational.jpg'),
(18, 'Hobby & freetime', 'pictures/category/hobbies_leisure.jpg'),
(19, 'Journals, Magazines', 'pictures/category/journals_magazines.jpg'),
(20, '18+', 'pictures/category/18+.jpg'),
(21, 'Sci-fi', 'pictures/category/sci-fi.jpg'),
(22, 'Family', 'pictures/category/family.jpg'),
(23, 'Romantic', 'pictures/category/romantic.jpg'),
(24, 'TV-Series', 'pictures/category/tv-series.jpg'),
(25, 'Horror, Thriller', 'pictures/category/horror_thriller.jpg'),
(26, 'Comedy', 'pictures/category/comedy.jpg'),
(27, 'Poems', 'pictures/category/poems.jpg'),
(28, 'Adventure', 'pictures/category/adventure.jpg'),
(29, 'Action', 'pictures/category/action.jpg'),
(30, 'Crime', 'pictures/category/crime.jpg'),
(31, 'Informative', 'pictures/category/informative.jpg'),
(32, 'Associate Science', 'pictures/category/associate-science.jpg'),
(33, 'Reference books', 'pictures/category/reference-books.jpg');

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `categoryinterest`
--

CREATE TABLE `categoryinterest` (
  `id` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `categoryId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `color`
--

CREATE TABLE `color` (
  `id` int(11) NOT NULL,
  `code` varchar(8) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- A tábla adatainak kiíratása `color`
--

INSERT INTO `color` (`id`, `code`) VALUES
(1, '#E8B5A0'),
(2, '#00FF00'),
(3, '#0000FF'),
(4, '#FFFF00'),
(5, '#FF00FF'),
(6, '#00FFFF'),
(7, '#800000'),
(8, '#008000'),
(9, '#000080'),
(10, '#808000'),
(11, '#800080'),
(12, '#008080'),
(13, '#C0C0C0'),
(14, '#808080'),
(15, '#FFA500'),
(16, '#A52A2A'),
(17, '#800080'),
(18, '#800000'),
(19, '#2F4F4F'),
(20, '#4B0082'),
(21, '#FFFFFF'),
(22, '#dad2e4'),
(23, '#c5aaee'),
(24, '#050505'),
(25, '#d0a65d');

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `follow`
--

CREATE TABLE `follow` (
  `id` int(11) NOT NULL,
  `followerId` int(11) NOT NULL,
  `followedId` int(11) NOT NULL,
  `followingTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `forgotpassword`
--

CREATE TABLE `forgotpassword` (
  `id` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `code` char(6) NOT NULL,
  `sendTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `general`
--

CREATE TABLE `general` (
  `id` int(11) NOT NULL,
  `birthdate` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `helpcenter`
--

CREATE TABLE `helpcenter` (
  `id` int(11) NOT NULL,
  `question` text NOT NULL,
  `answer` text DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- A tábla adatainak kiíratása `helpcenter`
--

INSERT INTO `helpcenter` (`id`, `question`, `answer`, `active`) VALUES
(1, 'What format should I use to upload an image? How can I convert it if the format is incorrect?', 'Our site only accepts images in the .jpg format. To convert your file, please visit Cloudconvert (link) and select the file you want to convert by clicking on the \'Select file\' button. Then, in the box that appears after the text \'convert to\', please select the .jpg format under \'images\' and press the \'Convert\' button.\r\nPlease note that our site only allows image uploads that are 2MB or smaller.', 1),
(2, 'What format  should I use to upload a file? How can I convert it if the format is incorrect?', 'Our site only accepts files in the .pdf format. To convert your file, please visit Cloudconvert (link) and select the file you want to convert by clicking on the \'Select file\' button. Then, in the box that appears after the text \'convert to\', please select the .pdf format under \'document\' and press the \'Convert\' button.\r\nPlease note that our site only allows file uploads that are 5MB or smaller.', 1),
(3, 'What are the differences between self-publishing and finding a publisher to publish my book?', 'When a user seeks a publisher for their book, it will only be visible to publisher profiles until a publisher decides to publish the work. The platform will notify the author by email if a publisher decides to publish the book. In this case, the price will be set by the publisher and the author\'s fees will be discussed with the publisher. Once published, both the author\'s and publisher\'s names will be displayed, and the books will only be visible to \'general\' users. From then on, the publisher owns your work.\r\nIf you decide to publish the book yourself, you must set the price of the book. In order to transfer the profits from the book to the author, we also need a bank account number. In this case, the book will only be visible to \'general\' profiles.\r\nNo matter which publishing method is chosen, the author will be able to change it at any time in the future.', 1),
(4, 'What is the difference between the \'General\' profile and the \'Publisher\' profile?', 'General profiles can view both published and self-published books. They can also view any user profile. During registration, we require your date of birth to ensure that you are over 15 years old, which is the minimum age limit on our site. Additionally, we have to know if you under 18 years of age, as our site allows the publication of books that may contain adult content.\r\nTo register a publisher profile, please provide the name of your company. Our system will only display books that have not yet been published and are marked for publisher search. Publisher profiles are restricted to viewing general user profiles.', 1),
(5, 'How do I buy a book on our site and what payment options are available?', 'Our site accepts credit card payments. Additionally, you have the option to purchase individual books. This means that if you find a book you like, you can pay for it immediately without having to add it to your shopping cart. Once the transaction is complete, you can continue browsing and exploring other books, or view the purchased book in the \'Purchased Books\' section of \'My Books\'.', 1),
(6, 'If I delete my profile, what will happen to my account and books?', 'Clicking on the \'Delete Profile\' button will make your profile inactive, but it cannot be completely deleted. However, you cannot undo this move.\r\nPlease note that once your profile is inactive, you will no longer be able to access the books you have purchased on our site.\r\nIf you have self-published on our site, your books will be removed, but if you have published through a publisher, they will still be available to other users. This is because the publisher owns your work after publication.\r\nIf a publisher profile is deleted and a book has already been published through our site, those books will automatically be given publisher lookup book status.', 1),
(7, 'How do I access the books I\'ve purchased?', 'To view all the books you have purchased, navigate to \'My Books\' and select \'Purchased Books\'. To start reading a book, click on the \'Start Reading\' button located in the \'Show Details\' window of the book card.\r\nPlease note that the books you have purchased are only accessible through our site.', 1),
(8, 'Are there any fees or costs associated with publishing my book?', 'Our pricing policy is as follows: The actual price of the book is determined by adding 20% to the publisher/author\'s price. Customers will pay this amount, but the publisher/author will receive the amount they specified. Publishing on our platform is basically free to the author or publisher. The 20% we add is used to maintain and develop our platform.', 1);

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `language`
--

CREATE TABLE `language` (
  `id` int(11) NOT NULL,
  `code` char(2) NOT NULL,
  `language` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- A tábla adatainak kiíratása `language`
--

INSERT INTO `language` (`id`, `code`, `language`) VALUES
(1, 'HU', 'Hungarian'),
(2, 'EN', 'English'),
(3, 'DE', 'German'),
(4, 'FR', 'French'),
(5, 'IT', 'Italian');

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `payment`
--

CREATE TABLE `payment` (
  `id` int(11) NOT NULL,
  `bookShoppingId` int(11) NOT NULL,
  `invoiceNumber` varchar(20) NOT NULL,
  `invoice` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `post`
--

CREATE TABLE `post` (
  `id` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `description` varchar(1000) NOT NULL,
  `postTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `postlike`
--

CREATE TABLE `postlike` (
  `id` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `postId` int(11) NOT NULL,
  `likeTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `publisher`
--

CREATE TABLE `publisher` (
  `id` int(11) NOT NULL,
  `companyName` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `saved`
--

CREATE TABLE `saved` (
  `id` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `bookId` int(11) NOT NULL,
  `savedTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `targetaudience`
--

CREATE TABLE `targetaudience` (
  `id` int(11) NOT NULL,
  `name` varchar(20) NOT NULL,
  `minAge` int(10) UNSIGNED NOT NULL,
  `maxAge` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- A tábla adatainak kiíratása `targetaudience`
--

INSERT INTO `targetaudience` (`id`, `name`, `minAge`, `maxAge`) VALUES
(1, 'Children', 5, 10),
(2, 'Teenagers', 13, 19),
(3, 'Young Adults', 18, 25),
(4, 'Adults', 21, 60),
(5, 'Elderly', 60, 100),
(6, 'General Audience', 0, 100);

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `user`
--

CREATE TABLE `user` (
  `id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `email` varchar(50) NOT NULL,
  `password` varchar(100) NOT NULL COMMENT 'Alma123*',
  `rank` enum('general','publisher','admin','') NOT NULL,
  `firstName` varchar(50) NOT NULL,
  `lastName` varchar(50) NOT NULL,
  `phoneNumber` varchar(15) DEFAULT NULL,
  `publicEmail` tinyint(1) NOT NULL DEFAULT 0,
  `publicPhoneNumber` tinyint(1) NOT NULL DEFAULT 0,
  `introDescription` varchar(1000) DEFAULT NULL,
  `website` varchar(100) DEFAULT NULL,
  `image` varchar(100) DEFAULT 'pictures/default-profile-pic-man.png',
  `registrationTime` timestamp NOT NULL DEFAULT current_timestamp(),
  `firstLogin` tinyint(1) NOT NULL DEFAULT 1,
  `deleted` tinyint(1) NOT NULL DEFAULT 0,
  `coverColorId` int(11) NOT NULL DEFAULT 1,
  `userId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexek a kiírt táblákhoz
--

--
-- A tábla indexei `aszf`
--
ALTER TABLE `aszf`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `book`
--
ALTER TABLE `book`
  ADD PRIMARY KEY (`id`),
  ADD KEY `writerId` (`writerId`),
  ADD KEY `publisherId` (`publisherId`),
  ADD KEY `languageId` (`languageId`),
  ADD KEY `categoryId` (`categoryId`),
  ADD KEY `targetAudienceId` (`targetAudienceId`);

--
-- A tábla indexei `bookrating`
--
ALTER TABLE `bookrating`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ratingerId` (`ratingerId`),
  ADD KEY `bookId` (`bookId`);

--
-- A tábla indexei `bookreport`
--
ALTER TABLE `bookreport`
  ADD PRIMARY KEY (`id`),
  ADD KEY `userId` (`userId`),
  ADD KEY `bookId` (`bookId`);

--
-- A tábla indexei `bookshopping`
--
ALTER TABLE `bookshopping`
  ADD PRIMARY KEY (`id`),
  ADD KEY `userId` (`userId`),
  ADD KEY `bookId` (`bookId`);

--
-- A tábla indexei `category`
--
ALTER TABLE `category`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `categoryinterest`
--
ALTER TABLE `categoryinterest`
  ADD PRIMARY KEY (`id`),
  ADD KEY `userId` (`userId`),
  ADD KEY `categoryId` (`categoryId`);

--
-- A tábla indexei `color`
--
ALTER TABLE `color`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `follow`
--
ALTER TABLE `follow`
  ADD PRIMARY KEY (`id`),
  ADD KEY `followerId` (`followerId`),
  ADD KEY `followedId` (`followedId`);

--
-- A tábla indexei `forgotpassword`
--
ALTER TABLE `forgotpassword`
  ADD PRIMARY KEY (`id`),
  ADD KEY `userId` (`userId`);

--
-- A tábla indexei `general`
--
ALTER TABLE `general`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `helpcenter`
--
ALTER TABLE `helpcenter`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `language`
--
ALTER TABLE `language`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `payment`
--
ALTER TABLE `payment`
  ADD PRIMARY KEY (`id`),
  ADD KEY `bookShoppingId` (`bookShoppingId`);

--
-- A tábla indexei `post`
--
ALTER TABLE `post`
  ADD PRIMARY KEY (`id`),
  ADD KEY `userId` (`userId`);

--
-- A tábla indexei `postlike`
--
ALTER TABLE `postlike`
  ADD PRIMARY KEY (`id`),
  ADD KEY `userId` (`userId`),
  ADD KEY `postId` (`postId`);

--
-- A tábla indexei `publisher`
--
ALTER TABLE `publisher`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `saved`
--
ALTER TABLE `saved`
  ADD PRIMARY KEY (`id`),
  ADD KEY `userId` (`userId`),
  ADD KEY `bookId` (`bookId`);

--
-- A tábla indexei `targetaudience`
--
ALTER TABLE `targetaudience`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `user`
--
ALTER TABLE `user`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `coverColorId` (`coverColorId`),
  ADD KEY `userId` (`userId`);

--
-- A kiírt táblák AUTO_INCREMENT értéke
--

--
-- AUTO_INCREMENT a táblához `aszf`
--
ALTER TABLE `aszf`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `book`
--
ALTER TABLE `book`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `bookrating`
--
ALTER TABLE `bookrating`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `bookreport`
--
ALTER TABLE `bookreport`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `bookshopping`
--
ALTER TABLE `bookshopping`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `category`
--
ALTER TABLE `category`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;

--
-- AUTO_INCREMENT a táblához `categoryinterest`
--
ALTER TABLE `categoryinterest`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `color`
--
ALTER TABLE `color`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT a táblához `follow`
--
ALTER TABLE `follow`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `forgotpassword`
--
ALTER TABLE `forgotpassword`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `general`
--
ALTER TABLE `general`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `helpcenter`
--
ALTER TABLE `helpcenter`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT a táblához `language`
--
ALTER TABLE `language`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT a táblához `payment`
--
ALTER TABLE `payment`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `post`
--
ALTER TABLE `post`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `postlike`
--
ALTER TABLE `postlike`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `publisher`
--
ALTER TABLE `publisher`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `saved`
--
ALTER TABLE `saved`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `targetaudience`
--
ALTER TABLE `targetaudience`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT a táblához `user`
--
ALTER TABLE `user`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
