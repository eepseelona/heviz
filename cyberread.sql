-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Gép: 127.0.0.1
-- Létrehozás ideje: 2024. Máj 01. 19:31
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
CREATE DEFINER=`root`@`localhost` PROCEDURE `addBook` (IN `userIdIN` INT, IN `titleIN` VARCHAR(50), IN `descriptionIN` VARCHAR(1000), IN `targetAudienceIdIN` INT, IN `languageIdIN` INT, IN `adultFictionIN` BOOLEAN, IN `categoryIdIN` INT, IN `statusIN` INT, IN `priceIN` INT, IN `coverImageIN` VARCHAR(100), IN `fileIN` VARCHAR(100), IN `bankAccountNumberIN` VARCHAR(30), IN `chapterNumberIN` INT, OUT `result` INT)   BEGIN

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
                INSERT INTO `book` (`book`.`writerId`,`book`.`title`, `book`.`description`, `book`.`targetAudienceId`, `book`.`languageId`, `book`.`adultFiction`, `book`.`categoryId`, `book`.`status`, `book`.`coverImage`, `book`.`file`, `book`.`chapterNumber`, `book`.`price`)
                VALUES (userIdIN, titleIN, descriptionIN, targetAudienceIdIN, languageIdIN, adultFictionIN, categoryIdIN, statusText, coverImageIN, fileIN, chapterNumberIN, NULL);
                SET result = 1;
            ELSEIF statusIN = 2 THEN
                SET statusText = "self-published";

                INSERT INTO `book` (`book`.`writerId`,`book`.`title`, `book`.`description`, `book`.`targetAudienceId`, `book`.`languageId`, `book`.`adultFiction`, `book`.`categoryId`, `book`.`status`, `book`.`price`, `book`.`coverImage`, `book`.`file`, `book`.`bankAccountNumber`, `book`.`chapterNumber`)
                VALUES (userIdIN, titleIN, descriptionIN, targetAudienceIdIN, languageIdIN, adultFictionIN, categoryIdIN, statusText, priceIN, coverImageIN, fileIN, bankAccountNumberIN, chapterNumberIN);
                SET result = 1;
            END IF;
        END IF;
    END IF;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `addBookRating` (IN `userIdIN` INT, IN `bookIdIN` INT, IN `rating` INT, OUT `result` INT)   BEGIN


DECLARE rank VARCHAR(20);
SELECT `user`.`rank` INTO rank
FROM `user`
WHERE `user`.`id` = userIdIN;

IF rank = "general" THEN
    IF EXISTS (SELECT * FROM `bookshopping` WHERE `bookshopping`.`userId` = userId AND `bookshopping`.`bookId` = bookIdIN) THEN
        INSERT INTO `bookrating`(`bookrating`.`ratingerId`, `bookrating`.`bookId`, `bookrating`.`rating`)
        VALUES (userIdIN, bookIdIN, rating);

        SET result = 1;
    ELSE
        SET result = 2;
    END IF;
ELSEIF rank = "publisher" THEN
	INSERT INTO `bookrating`(`bookrating`.`ratingerId`, `bookrating`.`bookId`, `bookrating`.`rating`)
    VALUES (userIdIN, bookIdIN, rating);

    SET result = 1;
END IF;


END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `addBookShopping` (IN `userIdIN` INT, IN `bookIdIN` INT, OUT `result` INT)   BEGIN

	DECLARE rank VARCHAR(20);
    SELECT `user`.`rank` INTO rank
    FROM `user`
    WHERE `user`.`id` = userIdIN;
    
    IF rank = "general" THEN
    	IF NOT EXISTS (SELECT * FROM `book` WHERE `book`.`id` = bookIdIN) THEN 
        	SET result = 3;
        ELSE
        	IF EXISTS (SELECT * FROM `bookshopping` WHERE `bookshopping`.`userId` = userIdIN AND `bookshopping`.`bookId` = bookIdIN) THEN
            	SET result = 4;
            ELSE
                IF EXISTS (SELECT * FROM `saved` WHERE `saved`.`userId` = userIdIN AND `saved`.`bookId` = bookIdIN) THEN
                    DELETE FROM `saved`
                    WHERE `saved`.`userId` = userIdIN AND `saved`.`bookId` = bookIdIN;
                END IF;

                INSERT INTO `bookshopping` (`bookshopping`.`userId`, `bookshopping`.`bookId`)
                VALUES(userIdIN, bookIdIN);

                SET result = 1;
            END IF;
        END IF;
    ELSE
    	SET result = 2;
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `addCategoryInterest` (IN `userIdIN` INT, IN `categoryIds` TEXT)   BEGIN

    DECLARE counter INT DEFAULT 1;
    DECLARE categoryId INT(11);

    WHILE counter <= LENGTH(categoryIds) - LENGTH(REPLACE(categoryIds, ',', '')) + 1 DO
        SET categoryId = SUBSTRING_INDEX(SUBSTRING_INDEX(categoryIds, ',', counter), ',', -1);
        
        IF EXISTS(SELECT * FROM `category` WHERE `category`.`id` = categoryId) THEN
            IF NOT EXISTS(SELECT * FROM `categoryinterest` WHERE `categoryinterest`.`userId` = userIdIN AND `categoryinterest`.`categoryId` = categoryId) THEN
                INSERT INTO `categoryinterest` (`categoryinterest`.`userId`, `categoryinterest`.`categoryId`) 
                VALUES (userIdIN, categoryId);
            END IF;
        END IF;

        SET counter = counter + 1;
    END WHILE;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `addPasswordCode` (IN `emailIN` VARCHAR(50), IN `codeIN` CHAR(6))   BEGIN

	DECLARE userId INT;
    
    SELECT `user`.`id` INTO userId
    FROM `user`
    WHERE `user`.`email` = emailIN;
    
    INSERT INTO `forgotpassword` (`forgotpassword`.`userId`, `forgotpassword`.`code`)
    VALUES (userId, codeIN);

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

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteUser` (IN `userIdIN` INT)   BEGIN
	
    DECLARE rank VARCHAR(20);
    SELECT `user`.`rank` INTO rank
    FROM `user`
    WHERE `user`.`id` = userIdIN;

	UPDATE `user`
	SET `user`.`deleted` = 1
	WHERE `user`.`id` = userIdIN;
    
    IF rank = "publisher" THEN
    	UPDATE `book`
        SET `book`.`status` = "looking for a publisher", `book`.`publisherId` = NULL, `book`.`price` = NULL, `book`.`publisherBankAccountNumber` = NULL
        WHERE `book`.`publisherId` = userIdIN;
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
            LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
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
            WHERE `book`.`categoryId` = categoryIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by") AND `writer`.`deleted` = 0
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
            LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
            LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
            LEFT JOIN (
                SELECT `bookrating`.`bookId`,
                AVG(`bookrating`.`rating`) AS `rat`
                FROM `bookrating`
                GROUP BY `bookrating`.`bookId`
            ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
            INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
            LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
            INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
            WHERE `book`.`categoryId` = categoryIdIN AND `book`.`status` = "looking for a publisher" AND `writer`.`deleted` = 0
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `getFileViewerData` (IN `userIdIN` INT, IN `bookIdIN` INT, OUT `result` INT)   BEGIN


DECLARE rank VARCHAR(20);
SELECT `user`.`rank` INTO rank
FROM `user`
WHERE `user`.`id` = userIdIN;

IF rank = "general" THEN
    IF EXISTS (SELECT * FROM `bookshopping` WHERE `bookshopping`.`userId` = userId AND `bookshopping`.`bookId` = bookIdIN) THEN
        SELECT 
            `book`.`file`,
            `book`.`pagesNumber`
        FROM `book`
        WHERE `book`.`id` = bookIdIN;

        SET result = 1;
    ELSE
        SET result = 2;
    END IF;
ELSEIF rank = "publisher" THEN
	SELECT 
        `book`.`file`,
        `book`.`pagesNumber`
    FROM `book`
    WHERE `book`.`id` = bookIdIN;

    SET result = 1;
END IF;


END$$

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
                LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
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
                WHERE `book`.`categoryId` = categoryIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by") AND `writer`.`deleted` = 0
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
                LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
                LEFT JOIN (
                    SELECT `bookrating`.`bookId`,
                    AVG(`bookrating`.`rating`) AS `rat`
                    FROM `bookrating`
                    GROUP BY `bookrating`.`bookId`
                ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                WHERE `book`.`categoryId` = categoryIdIN AND `book`.`status` = "looking for a publisher" AND `writer`.`deleted` = 0
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
                LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
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
                WHERE `book`.`categoryId` = categoryIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by") AND `writer`.`deleted` = 0
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
                LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
                LEFT JOIN (
                    SELECT `bookrating`.`bookId`,
                    AVG(`bookrating`.`rating`) AS `rat`
                    FROM `bookrating`
                    GROUP BY `bookrating`.`bookId`
                ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                WHERE `book`.`categoryId` = categoryIdIN AND `book`.`status` = "looking for a publisher" AND `writer`.`deleted` = 0
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
                LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
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
                WHERE `book`.`categoryId` = categoryIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by") AND `writer`.`deleted` = 0
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
                LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
                LEFT JOIN (
                    SELECT `bookrating`.`bookId`,
                    AVG(`bookrating`.`rating`) AS `rat`
                    FROM `bookrating`
                    GROUP BY `bookrating`.`bookId`
                ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                WHERE `book`.`categoryId` = categoryIdIN AND `book`.`status` = "looking for a publisher" AND `writer`.`deleted` = 0
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
                LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
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
                WHERE `book`.`categoryId` = categoryIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by") AND `writer`.`deleted` = 0
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
                LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
                LEFT JOIN (
                    SELECT `bookrating`.`bookId`,
                    AVG(`bookrating`.`rating`) AS `rat`
                    FROM `bookrating`
                    GROUP BY `bookrating`.`bookId`
                ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                WHERE `book`.`categoryId` = categoryIdIN AND `book`.`status` = "looking for a publisher" AND `writer`.`deleted` = 0
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
                    LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
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
                    WHERE `book`.`categoryId` = categoryIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by") AND `writer`.`deleted` = 0
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
                    LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
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
                    WHERE `book`.`categoryId` = categoryIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by") AND `writer`.`deleted` = 0
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
                    LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
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
                    WHERE `book`.`categoryId` = categoryIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by") AND `writer`.`deleted` = 0
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
                    LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
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
                    WHERE `book`.`categoryId` = categoryIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by") AND `writer`.`deleted` = 0
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
                    LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
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
                    `book`.`status` = "self-published" AND `writer`.`deleted` = 0;
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
                    LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
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
                    `book`.`status` = "published by" AND `writer`.`deleted` = 0;
                END IF;
            END IF;
        END IF;
        
        SET result = 1;
    
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getFilteredPayedBooks` (IN `userIdIN` INT, IN `filter` INT, OUT `result` INT, OUT `userRank` VARCHAR(20))   BEGIN

	DECLARE rank VARCHAR(20);

	IF filter < 1 OR filter > 10 THEN
    	SET result = 2;
    ELSE

        SELECT `user`.`rank` INTO rank 
        FROM `user`
        WHERE `user`.`id` = userIdIN;
        SET userRank = rank;

            IF rank = "general" THEN
            	IF filter = 1 THEN
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
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
                    LEFT JOIN (
                        SELECT `bookrating`.`bookId`,
                        AVG(`bookrating`.`rating`) AS `rat`
                        FROM `bookrating`
                        GROUP BY `bookrating`.`bookId`
                    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                    LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id`
                    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                    WHERE `bookShopping`.`userId` = userIdIN
                    ORDER BY `book`.`title` ASC;
                ELSEIF filter = 2 THEN
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
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
                    LEFT JOIN (
                        SELECT `bookrating`.`bookId`,
                        AVG(`bookrating`.`rating`) AS `rat`
                        FROM `bookrating`
                        GROUP BY `bookrating`.`bookId`
                    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                    LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id`
                    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                    WHERE `bookShopping`.`userId` = userIdIN
                    ORDER BY `book`.`title` DESC;
                ELSEIF filter = 3 THEN
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
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
                    LEFT JOIN (
                        SELECT `bookrating`.`bookId`,
                        AVG(`bookrating`.`rating`) AS `rat`
                        FROM `bookrating`
                        GROUP BY `bookrating`.`bookId`
                    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                    LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id`
                    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                    WHERE `bookShopping`.`userId` = userIdIN
                    ORDER BY `book`.`publishedTime` ASC;
                ELSEIF filter = 4 THEN
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
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
                    LEFT JOIN (
                        SELECT `bookrating`.`bookId`,
                        AVG(`bookrating`.`rating`) AS `rat`
                        FROM `bookrating`
                        GROUP BY `bookrating`.`bookId`
                    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                    LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id`
                    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                    WHERE `bookShopping`.`userId` = userIdIN
                    ORDER BY `book`.`publishedTime` DESC;
                ELSEIF filter = 5 THEN
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
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
                    LEFT JOIN (
                        SELECT `bookrating`.`bookId`,
                        AVG(`bookrating`.`rating`) AS `rat`
                        FROM `bookrating`
                        GROUP BY `bookrating`.`bookId`
                    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                    LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id`
                    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                    WHERE `bookShopping`.`userId` = userIdIN
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
                        `book`.`price`,
                        `writer`.`username`,
                        `category`.`name`,
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
                    LEFT JOIN (
                        SELECT `bookrating`.`bookId`,
                        AVG(`bookrating`.`rating`) AS `rat`
                        FROM `bookrating`
                        GROUP BY `bookrating`.`bookId`
                    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                    LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id`
                    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                    WHERE `bookShopping`.`userId` = userIdIN
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
                        `book`.`price`,
                        `writer`.`username`,
                        `category`.`name`,
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
                    LEFT JOIN (
                        SELECT `bookrating`.`bookId`,
                        AVG(`bookrating`.`rating`) AS `rat`
                        FROM `bookrating`
                        GROUP BY `bookrating`.`bookId`
                    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                    LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id`
                    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                    WHERE `bookShopping`.`userId` = userIdIN
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
                        `book`.`price`,
                        `writer`.`username`,
                        `category`.`name`,
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
                    LEFT JOIN (
                        SELECT `bookrating`.`bookId`,
                        AVG(`bookrating`.`rating`) AS `rat`
                        FROM `bookrating`
                        GROUP BY `bookrating`.`bookId`
                    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                    LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id`
                    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                    WHERE `bookShopping`.`userId` = userIdIN
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
                        `book`.`price`,
                        `writer`.`username`,
                        `category`.`name`,
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
                    LEFT JOIN (
                        SELECT `bookrating`.`bookId`,
                        AVG(`bookrating`.`rating`) AS `rat`
                        FROM `bookrating`
                        GROUP BY `bookrating`.`bookId`
                    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                    LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id`
                    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                    WHERE `bookShopping`.`userId` = userIdIN AND
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
                        `book`.`price`,
                        `writer`.`username`,
                        `category`.`name`,
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
                    LEFT JOIN (
                        SELECT `bookrating`.`bookId`,
                        AVG(`bookrating`.`rating`) AS `rat`
                        FROM `bookrating`
                        GROUP BY `bookrating`.`bookId`
                    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                    LEFT JOIN `bookShopping` ON `bookShopping`.`bookId` = `book`.`id`
                    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                    WHERE `bookShopping`.`userId` = userIdIN AND
                    `book`.`status` = "published by";
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
                    `publish`.`username` AS "publisher username"
                FROM `book`
                INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
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
                WHERE `saved`.`userId` = userIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by") AND `writer`.`deleted` = 0
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
                LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
                LEFT JOIN (
                    SELECT `bookrating`.`bookId`,
                    AVG(`bookrating`.`rating`) AS `rat`
                    FROM `bookrating`
                    GROUP BY `bookrating`.`bookId`
                ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                WHERE `saved`.`userId` = userIdIN AND `book`.`status` = "looking for a publisher" AND `writer`.`deleted` = 0
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
                    `publish`.`username` AS "publisher username"
                FROM `book`
                INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
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
                WHERE `saved`.`userId` = userIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by") AND `writer`.`deleted` = 0
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
                LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
                LEFT JOIN (
                    SELECT `bookrating`.`bookId`,
                    AVG(`bookrating`.`rating`) AS `rat`
                    FROM `bookrating`
                    GROUP BY `bookrating`.`bookId`
                ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                WHERE `saved`.`userId` = userIdIN AND `book`.`status` = "looking for a publisher" AND `writer`.`deleted` = 0
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
                    `publish`.`username` AS "publisher username"
                FROM `book`
                INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
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
                WHERE `saved`.`userId` = userIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by") AND `writer`.`deleted` = 0
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
                LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
                LEFT JOIN (
                    SELECT `bookrating`.`bookId`,
                    AVG(`bookrating`.`rating`) AS `rat`
                    FROM `bookrating`
                    GROUP BY `bookrating`.`bookId`
                ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                WHERE `saved`.`userId` = userIdIN AND `book`.`status` = "looking for a publisher" AND `writer`.`deleted` = 0
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
                    `publish`.`username` AS "publisher username"
                FROM `book`
                INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
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
                WHERE `saved`.`userId` = userIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by") AND `writer`.`deleted` = 0
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
                LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
                LEFT JOIN (
                    SELECT `bookrating`.`bookId`,
                    AVG(`bookrating`.`rating`) AS `rat`
                    FROM `bookrating`
                    GROUP BY `bookrating`.`bookId`
                ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
                INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
                LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
                INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
                WHERE `saved`.`userId` = userIdIN AND `book`.`status` = "looking for a publisher" AND `writer`.`deleted` = 0
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
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
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
                    WHERE `saved`.`userId` = userIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by") AND `writer`.`deleted` = 0
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
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
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
                    WHERE `saved`.`userId` = userIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by") AND `writer`.`deleted` = 0
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
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
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
                    WHERE `saved`.`userId` = userIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by") AND `writer`.`deleted` = 0
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
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
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
                    WHERE `saved`.`userId` = userIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by") AND `writer`.`deleted` = 0
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
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
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
                    `book`.`status` = "self-published" AND `writer`.`deleted` = 0;
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
                        `publish`.`username` AS "publisher username"
                    FROM `book`
                    INNER JOIN `user` AS `writer` ON `writer`.`id` = `book`.`writerId`
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
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
                    `book`.`status` = "published by" AND `writer`.`deleted` = 0;
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
    `book`.`status` != "looking for a publisher" AND
    `writer`.`deleted` = 0
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
`book`.`status` != "looking for a publisher" AND `writer`.`deleted` = 0
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
WHERE `book`.`status` = "looking for a publisher" AND `writer`.`deleted` = 0
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
    LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `getPublishedBookDetails` (IN `userIdIN` INT, IN `bookIdIN` INT, OUT `result` INT)   BEGIN

	DECLARE rank VARCHAR(20);
    SELECT `user`.`rank` INTO rank
    FROM `user`
    WHERE `user`.`id` = userIdIN;

    IF rank = "publisher" THEN

        IF EXISTS (SELECT * FROM `book` WHERE `book`.`id` = bookIdIN AND `book`.`publisherId` = userIdIN) THEN
            SELECT `book`.`price`, `book`.`publisherBankAccountNumber`
            FROM `book`
            WHERE `book`.`id` = bookIdIN AND `book`.`publisherId` = userIdIN;

            SET result = 1;
        ELSEIF NOT EXISTS (SELECT * FROM `book` WHERE `book`.`id` = bookIdIN) THEN
            SET result = 3;
        ELSEIF EXISTS (SELECT * FROM `book` WHERE `book`.`id` = bookIdIN) AND ((SELECT `book`.`publisherId` FROM `book` WHERE `book`.`id` = bookIdIN) != userIdIN OR (SELECT `book`.`publisherId` FROM `book` WHERE `book`.`id` = bookIdIN) IS NULL) THEN
            SET result = 4;
        END IF;

    ELSE
        SET result = 2;
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
`book`.`writerId` != userIdIN AND
`writer`.`deleted` = 0
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
LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
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
        `book`.`categoryId` = cId AND `writer`.`deleted` = 0
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
`book`.`status` != "looking for a publisher" AND `writer`.`deleted` = 0
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
`book`.`status` = "looking for a publisher" AND
`writer`.`deleted` = 0
ORDER BY 
    RAND()
LIMIT 9$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getRecommandedUsers` (IN `userIdIN` INT)   BEGIN

DECLARE rank VARCHAR(20);
DECLARE followingCount INT;
DECLARE userCount INT;
DECLARE additionalUsers INT;

SELECT `user`.`rank` INTO rank
FROM `user`
WHERE `user`.`id` = userIdIN;

SELECT COUNT(*) INTO followingCount
FROM `follow`
WHERE `followerId` = userIdIN;

IF rank = "general" THEN

    SELECT COUNT(*) INTO followingCount
    FROM `book`
    WHERE `writerId` = userIdIN AND (`status` = 'published by' OR `status` = 'self-published');

    IF followingCount = 0 THEN
        SELECT COUNT(*) INTO userCount
        FROM `user`
        WHERE `deleted` = 0;
        
        IF userCount < 4 THEN
            SET additionalUsers = 4 - userCount;
        END IF;
        
        SELECT DISTINCT `user`.`image`, `user`.`username`
        FROM `user`
        WHERE `deleted` = 0
        AND `user`.`id` IN (
            SELECT DISTINCT `user`.`id`
            FROM `user`
            INNER JOIN `book` ON `user`.`id` = `book`.`writerId`
            WHERE `book`.`status` = 'published by' OR `book`.`status` = 'self-published'
        )
        ORDER BY RAND()
        LIMIT 4;
        
        IF userCount < 4 THEN
            INSERT INTO resultTable (image, username)
            SELECT DISTINCT `user`.`image`, `user`.`username`
            FROM `user`
            WHERE `deleted` = 0
            AND `user`.`id` NOT IN (
                SELECT DISTINCT `user`.`id`
                FROM `user`
                INNER JOIN `book` ON `user`.`id` = `book`.`writerId`
                WHERE `book`.`status` = 'published by' OR `book`.`status` = 'self-published'
            )
            ORDER BY RAND()
            LIMIT additionalUsers;
        END IF;
        
    ELSE
        SELECT DISTINCT `user`.`image`, `user`.`username`
        FROM `user`
        INNER JOIN `follow` ON `user`.`id` = `follow`.`followerId`
        INNER JOIN `book` ON `user`.`id` = `book`.`writerId`
        WHERE `follow`.`followedId` IN (
            SELECT DISTINCT `user`.`id`
            FROM `user`
            INNER JOIN `follow` ON `user`.`id` = `follow`.`followedId`
            WHERE `follow`.`followerId` = userIdIN
        )
        AND (`book`.`status` = 'published by' OR `book`.`status` = 'self-published')
        AND `user`.`id` != userIdIN
        AND `user`.`deleted` = 0
        LIMIT 4;
    END IF;
    
ELSEIF rank = "publisher" THEN

    SELECT COUNT(*) INTO followingCount
    FROM `book`
    WHERE `writerId` IN (
        SELECT DISTINCT `user`.`id`
        FROM `user`
        INNER JOIN `book` ON `user`.`id` = `book`.`writerId`
        WHERE `book`.`status` = 'looking for a publisher'
    );

    IF followingCount = 0 THEN
        SELECT COUNT(*) INTO userCount
        FROM `user`
        WHERE `deleted` = 0;
        
        IF userCount < 4 THEN
            SET additionalUsers = 4 - userCount;
        END IF;
        
        SELECT DISTINCT `user`.`image`, `user`.`username`
        FROM `user`
        WHERE `deleted` = 0
        ORDER BY RAND()
        LIMIT 4;
        
        IF userCount < 4 THEN
            INSERT INTO resultTable (image, username)
            SELECT DISTINCT `user`.`image`, `user`.`username`
            FROM `user`
            WHERE `deleted` = 0
            ORDER BY RAND()
            LIMIT additionalUsers;
        END IF;
        
    ELSE
        SELECT DISTINCT `user`.`image`, `user`.`username`
        FROM `user`
        INNER JOIN `follow` ON `user`.`id` = `follow`.`followerId`
        INNER JOIN `book` ON `user`.`id` = `book`.`writerId`
        WHERE `follow`.`followedId` IN (
            SELECT DISTINCT `user`.`id`
            FROM `user`
            INNER JOIN `follow` ON `user`.`id` = `follow`.`followedId`
            WHERE `follow`.`followerId` = userIdIN
        )
        AND `book`.`status` = 'looking for a publisher'
        AND `user`.`id` != userIdIN
        AND `user`.`deleted` = 0
        LIMIT 4;
    END IF;

END IF;

END$$

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
        LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
        LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
        LEFT JOIN (
            SELECT `bookrating`.`bookId`,
            AVG(`bookrating`.`rating`) AS `rat`
            FROM `bookrating`
            GROUP BY `bookrating`.`bookId`
        ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
        INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
        LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id`
        WHERE `saved`.`userId` = userIdIN AND `book`.`categoryId` = categoryIdIN AND `writer`.`deleted` = 0;
        
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
    LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
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
    WHERE `saved`.`userId` = userIdIN AND (`book`.`status` = "self-published" OR `book`.`status` = "published by") AND `writer`.`deleted` = 0;
    
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
    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
    LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
    LEFT JOIN (
        SELECT `bookrating`.`bookId`,
        AVG(`bookrating`.`rating`) AS `rat`
        FROM `bookrating`
        GROUP BY `bookrating`.`bookId`
    ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
    INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
    LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id`
    INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
    WHERE `saved`.`userId` = userIdIN AND `book`.`status` = "looking for a publisher" AND `writer`.`deleted` = 0;

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
        LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
        LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
        LEFT JOIN (
            SELECT `bookrating`.`bookId`,
            AVG(`bookrating`.`rating`) AS `rat`
            FROM `bookrating`
            GROUP BY `bookrating`.`bookId`
        ) AS `bookrat` ON `bookrat`.`bookId` = `book`.`id`
        INNER JOIN `language` ON `language`.`id` = `book`.`languageId`
        LEFT JOIN `saved` ON `saved`.`bookId` = `book`.`id` AND `saved`.`userId` = userIdIN
        INNER JOIN `category` ON `category`.`id` = `book`.`categoryId`
        WHERE (`book`.`title` LIKE CONCAT(searchTextIN, "%") OR `writer`.`firstName` LIKE CONCAT(searchTextIN, "%") OR `writer`.`lastName` LIKE CONCAT(searchTextIN, "%") OR `publisher`.`companyName` LIKE CONCAT(searchTextIN, "%")) AND `book`.`status` = "looking for a publisher" AND `writer`.`deleted` = 0
        ORDER BY `book`.`title` ASC, `writer`.`lastName` ASC, `writer`.`firstName` ASC;
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
        LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
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
        WHERE (`book`.`title` LIKE CONCAT(searchTextIN, "%") OR `writer`.`firstName` LIKE CONCAT(searchTextIN, "%") OR `writer`.`lastName` LIKE CONCAT(searchTextIN, "%") OR `publisher`.`companyName` LIKE CONCAT(searchTextIN, "%")) AND (`book`.`status` = "self-published" OR `book`.`status`= "published by") AND `writer`.`deleted` = 0
        ORDER BY `book`.`title` ASC, `writer`.`lastName` ASC, `writer`.`firstName` ASC;
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
`book`.`writerId` != userIdIN AND `writer`.`deleted` = 0
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
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
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
                    LEFT JOIN `user` AS `publish` ON `publish`.`id` = `book`.`publisherId`
                    LEFT JOIN `publisher` ON `publish`.`userId` = `publisher`.`id`
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
            
            	IF (SELECT `user`.`deleted` FROM `user` WHERE `user`.`id` = profileUserId) = 0 THEN

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

			ELSE
            	SET result = 4;
            END IF;
            
        END IF;
        
    ELSE
    	SET result = 2;
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getUserDetails` (IN `userIdIN` INT, IN `usernameIN` VARCHAR(50), IN `profileUsernameIN` VARCHAR(50), OUT `result` INT, OUT `deleted` INT)   BEGIN
    DECLARE profileUserId INT;
    DECLARE profileUserRank VARCHAR(20);
    DECLARE userRank VARCHAR(20);
    DECLARE userIdMatch BOOLEAN;
    
    SELECT `user`.`rank` INTO userRank
    FROM `user`
    WHERE `user`.`id` = userIdIN;

    IF EXISTS (SELECT * FROM `user` WHERE `user`.`username` = profileUsernameIN) THEN
        SELECT `user`.`id` INTO profileUserId
        FROM `user`
        WHERE `user`.`username` = profileUsernameIN;
        
        SELECT `user`.`rank` INTO profileUserRank
        FROM `user`
        WHERE `user`.`id` = profileUserId;
        
        SET userIdMatch = (profileUserId = userIdIN);
        
        IF (SELECT `user`.`deleted` FROM `user` WHERE `user`.`id` = profileUserId) = 1 THEN
        	SET deleted = 1;
        ELSE
            IF userIdMatch = TRUE THEN
                IF userRank = "general" THEN
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

                    SET result = 1;
                ELSEIF userRank = "publisher" THEN
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

                    SET result = 1;
                END IF;
            ELSE
                IF profileUserRank = "general" AND userRank = "general" THEN
                    SELECT
                        `user`.`rank`,
                        `user`.`username`,
                        `user`.`image`,
                        IF(`follow`.`followerId` IS NOT NULL, TRUE, FALSE) AS `followed`,
                        `user`.`firstName`,
                        `user`.`lastName`,
                        (SELECT COUNT(`book`.`id`) FROM `book` WHERE `book`.`writerId` = profileUserId AND `book`.`status` != "looking for a publisher") AS bookCount,
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
                ELSEIF profileUserRank = "publisher" AND userRank = "general" THEN
                    SELECT
                        `user`.`rank`,
                        `user`.`username`,
                        `user`.`image`,
                        IF(`follow`.`followerId` IS NOT NULL, TRUE, FALSE) AS `followed`,
                        `publisher`.`companyName`,
                        (SELECT COUNT(`book`.`id`) FROM `book` WHERE `book`.`publisherId` = profileUserId AND `book`.`status` != "looking for a publisher") AS bookCount,
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
                ELSEIF userRank = "publisher" AND profileUserRank = "general" THEN
                    SELECT
                        `user`.`rank`,
                        `user`.`username`,
                        `user`.`image`,
                        IF(`follow`.`followerId` IS NOT NULL, TRUE, FALSE) AS `followed`,
                        `user`.`firstName`,
                        `user`.`lastName`,
                        (SELECT COUNT(`book`.`id`) FROM `book` WHERE `book`.`writerId` = profileUserId AND `book`.`status` = "looking for a publisher") AS bookCount,
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
                ELSEIF userRank = "publisher" AND profileUserRank = "publisher" THEN
                    SELECT
                        `user`.`rank`,
                        `user`.`username`,
                        `user`.`image`,
                        IF(`follow`.`followerId` IS NOT NULL, TRUE, FALSE) AS `followed`,
                        `publisher`.`companyName`,
                        (SELECT COUNT(`book`.`id`) FROM `book` WHERE `book`.`publisherId` = profileUserId AND `book`.`status` = "looking for a publisher") AS bookCount,
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
            END IF;
            
            SET deleted = 0;
        END IF;
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `isValidEmail` (IN `emailIN` VARCHAR(50), OUT `result` INT)   BEGIN


IF EXISTS (SELECT * FROM `user` WHERE `user`.`email` = emailIN) THEN
	SET result = 1;
ELSE
	SET result = 2;
END IF;


END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `login` (IN `emailIN` VARCHAR(50), IN `passwordIN` VARCHAR(100), OUT `userIdOUT` INT, OUT `usernameOUT` VARCHAR(50), OUT `firstNameOUT` VARCHAR(50), OUT `lastNameOUT` VARCHAR(50), OUT `imageOUT` VARCHAR(100), OUT `rankOUT` ENUM("admin","general","publisher"), OUT `activeOUT` BOOLEAN)   BEGIN

	IF (SELECT `user`.`deleted` FROM `user` WHERE `user`.`email` = emailIN) = 0 THEN
        SELECT `user`.`id`, `user`.`username`, `user`.`firstName`, `user`.`lastName`, `user`.`image`, `user`.`rank`, `user`.`firstLogin`
        INTO userIdOUT, usernameOUT, firstNameOUT, lastNameOUT, imageOUT, rankOUT, activeOUT
        FROM `user`
        WHERE `user`.`email` = emailIN AND `user`.`password` = SHA1(passwordIN);

        UPDATE `user`
        SET `user`.`firstLogin` = false
        WHERE `user`.`email` = emailIN;
    END IF;
        
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `publishBook` (IN `userIdIN` INT, IN `bookIdIN` INT, IN `priceIN` INT, IN `publisherBankAccountNumberIN` VARCHAR(30), OUT `result` INT)   BEGIN

	DECLARE rank VARCHAR(20);
    SELECT `user`.`rank` INTO rank
    FROM `user`
    WHERE `user`.`id` = userIdIN;
    
    IF rank = "publisher" THEN
        IF NOT EXISTS (SELECT * FROM `book` WHERE `book`.`id` = bookIdIN) THEN
            SET result = 2;
        ELSEIF (SELECT `book`.`status` FROM `book` WHERE `book`.`id` = bookIdIN) != "looking for a publisher" THEN
            SET result = 3;
        ELSE
            UPDATE `book`
            SET `book`.`status` = "published by", `book`.`publisherId` = userIdIN, `book`.`price` = priceIN, `book`.`publisherBankAccountNumber` = publisherBankAccountNumberIN
            WHERE `book`.`id` = bookIdIN;
            
            SET result = 1;
        END IF;
    ELSE
    	SET result = 4;
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `setBook` (IN `bookIdIN` INT, IN `titleIN` VARCHAR(50), IN `descriptionIN` VARCHAR(1000), IN `targetAudienceIdIN` INT, IN `languageIdIN` INT, IN `adultFictionIN` BOOLEAN, IN `categoryIdIN` INT, IN `statusIdIN` INT, IN `priceIN` INT, IN `coverImageIN` VARCHAR(100), IN `fileIN` VARCHAR(100), IN `bankAccountNumberIN` VARCHAR(30), IN `chapterNumberIN` INT, OUT `result` INT)   BEGIN

	DECLARE userId INT;
    
    SELECT `book`.`writerId` INTO userId FROM `book` WHERE `book`.`id` = bookIdIN;
    
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `setPhoneNumber` (IN `userIdIN` INT, IN `phoneNumberIN` VARCHAR(15))   BEGIN

	IF phoneNumberIN = "" THEN
    	UPDATE `user`
        SET `user`.`phoneNumber` = NULL
        WHERE `user`.`id` = userIdIN;
    ELSE
        UPDATE `user`
        SET `user`.`phoneNumber` = phoneNumberIN
        WHERE `user`.`id` = userIdIN;
    END IF;
    
END$$

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

CREATE DEFINER=`root`@`localhost` PROCEDURE `setPublishedBookDetails` (IN `userIdIN` INT, IN `bookIdIN` INT, IN `newPriceIN` INT, IN `newPublisherBankAccountNumberIN` VARCHAR(30), OUT `result` INT)   BEGIN


DECLARE rank VARCHAR(20);
SELECT `user`.`rank` INTO rank
FROM `user`
WHERE `user`.`id` = userIdIN;

IF rank = "publisher" THEN
	
    IF EXISTS (SELECT * FROM `book` WHERE `book`.`id` = bookIdIN AND `book`.`publisherId` = userIdIN) THEN
        UPDATE `book` 
        SET `book`.`price` = newPriceIN, `book`.`publisherBankAccountNumber` = newPublisherBankAccountNumberIN
        WHERE `book`.`id` = bookIdIN AND `book`.`publisherId` = userIdIN;
        
        SET result = 1;
    ELSEIF NOT EXISTS (SELECT * FROM `book` WHERE `book`.`id` = bookIdIN) THEN
    	SET result = 3;
    ELSEIF EXISTS (SELECT * FROM `book` WHERE `book`.`id` = bookIdIN) AND ((SELECT `book`.`publisherId` FROM `book` WHERE `book`.`id` = bookIdIN) != userIdIN OR (SELECT `book`.`publisherId` FROM `book` WHERE `book`.`id` = bookIdIN) IS NULL) THEN
    	SET result = 4;
    END IF;
    
ELSE
	SET result = 2;
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `unpublishBook` (IN `userIdIN` INT, IN `bookIdIN` INT, OUT `result` INT)   BEGIN

	DECLARE rank VARCHAR(20);
    SELECT `user`.`rank` INTO rank
    FROM `user`
    WHERE `user`.`id` = userIdIN;
    
    IF rank = "publisher" THEN
    	IF NOT EXISTS (SELECT * FROM `book` WHERE `book`.`id` = bookIdIN) THEN
        	SET result = 3;
        ELSE
        	IF (SELECT `book`.`publisherId` FROM `book` WHERE `book`.`id` = bookIdIN) = userIdIN THEN
            	UPDATE `book`
                SET `book`.`status` = "looking for a publisher", `book`.`price` = NULL, `book`.`publisherBankAccountNumber` = NULL, `book`.`publisherId` = NULL
                WHERE `book`.`id` = bookIdIN;
                
                SET result = 1;
            ELSE
            	SET result = 4;
            END IF;
        END IF;
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
  `pagesNumber` int(10) UNSIGNED NOT NULL,
  `adultFiction` tinyint(1) NOT NULL,
  `bankAccountNumber` varchar(30) DEFAULT NULL,
  `publisherBankAccountNumber` varchar(30) DEFAULT NULL,
  `languageId` int(11) NOT NULL,
  `targetAudienceId` int(11) NOT NULL,
  `categoryId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- A tábla adatainak kiíratása `book`
--

INSERT INTO `book` (`id`, `title`, `status`, `writerId`, `publisherId`, `publishedTime`, `description`, `price`, `coverImage`, `file`, `chapterNumber`, `pagesNumber`, `adultFiction`, `bankAccountNumber`, `publisherBankAccountNumber`, `languageId`, `targetAudienceId`, `categoryId`) VALUES
(1, 'With Love, from Cold World', 'self-published', 7, NULL, '2024-01-12 14:55:53', 'Lauren is a serious bookkeeper at a theme park where it\'s always winter, which doesn\'t get quite the crowds as its more famous counterparts.', 3000, 'pictures/book/with-love-from-cold-world', 'book/a_mennyeknel_sulyosabb_', 0, 400, 1, '1234567890123456', NULL, 2, 3, 1),
(2, 'Long Shot', 'self-published', 7, NULL, '2024-02-24 15:03:41', 'A triumphant story of a domestic violence survivor creating her happy-ever-after. Ambitious college graduate Iris DuPree stays with Caleb Bradley, her basketball-player boyfriend, because of an unexpected pregnancy, though she has her own career goals and feels an electric connection with his rival, August West.', 4500, 'pictures/book/long-shot', 'book/a_mennyeknel_sulyosabb_', 1, 539, 1, '2345678910234567', NULL, 2, 3, 2),
(3, 'Red Mars', 'self-published', 7, NULL, '2024-04-08 14:07:48', 'or centuries, Mars has beckoned to mankind to come and conquer its hostile climate. Now, in the year 2026, a group of one hundred colonists is about to fulfill that destiny. John Boone, Maya Toitavna, Frank Chalmers, and Arkady Bogdanov lead a mission whose ultimate goal is the terraforming of Mars.', 6000, 'pictures/book/red-mars', 'book/a_mennyeknel_sulyosabb_', 1, 592, 1, '3456789021434567', NULL, 2, 3, 3),
(4, 'Holly', 'looking for a publisher', 5, NULL, '2024-02-24 15:12:18', 'Holly is on her own, and up against a pair of unimaginably depraved and brilliantly disguised adversaries. When Penny Dahl callt the Finders Keepers detective...', NULL, 'pictures/book/holly', 'book/a_mennyeknel_sulyosabb_', 1, 448, 1, NULL, NULL, 2, 3, 4),
(5, 'Shatter Me', 'published by', 5, 22, '2024-03-29 15:15:22', 'The Shatter Me series is the story of a teenage girl who has never been able to experience human touch without inflicting extreme pain.', 3000, 'pictures/book/shatter-me', 'book/a_mennyeknel_sulyosabb_', 1, 290, 1, '5678901234655789', '98514215312312', 2, 3, 5),
(6, 'Zeno\'s Conscience', 'self-published', 9, NULL, '2024-03-23 15:18:54', 'In Zeno\'s Conscience by Italo Svevo, we are introduced to Zeno Cosini, a middle-aged businessman who seeks psychiatric help to quit smoking. The novel is structured as a series of memoirs, written by Zeno himself, at the request of his psychiatrist.', 4500, 'pictures/book/zenos-conscience', 'book/Csontvaros', 1, 464, 1, '6789012345766890', NULL, 5, 3, 6),
(7, 'The Name of the Rose', 'self-published', 9, NULL, '2024-04-03 14:21:28', 'It is a historical murder mystery set in an Italian monastery in the year 1327, and an intellectual mystery combining semiotics in fiction, biblical analysis, medieval studies, and literary theory.', 5000, 'pictures/book/the-name-of-the-rose', 'book/Csontvaros', 1, 512, 1, '7890123456877901', NULL, 5, 3, 7),
(8, 'The Late Mattia Pascal', 'self-published', 9, NULL, '2024-04-17 14:24:34', 'Mattia Pascal is a young Italian man. After his father\'s death, his family is ruined by the man who was supposed to help them, and Mattia finds himself in a miserable social condition. His wedding is not more happy : his mother-in-law, with whom he lives, hates him.', 6500, 'pictures/book/the-late-mattia-pascal', 'book/Csontvaros', 1, 272, 1, '8901234567988012', NULL, 5, 3, 8),
(9, 'Nine Perfect Strangers', 'self-published', 14, NULL, '2024-02-09 15:28:26', 'Set in Sydney, Australia, the novel follows a group of strangers who gather at a wellness retreat to receive treatment from a mysterious health guru. The novel was adapted for a 2021 television series starring Nicole Kidman, Melissa McCarthy, and Michael Shannon.', 5000, 'pictures/book/nine-perfect-strangers', 'book/Csontvaros', 1, 464, 1, '8012345678099123', NULL, 2, 3, 9),
(10, 'Eleanor Oliphant is Completely Fine', 'self-published', 14, NULL, '2024-02-23 15:30:06', 'The story centres on Eleanor Oliphant, a social misfit with a traumatic past who becomes enamoured with a singer, whom she believes she is destined to be with. The novel deals with themes of isolation and loneliness, and depicts Eleanor\'s transformational journey towards a fuller understanding of self and life.', 4800, 'pictures/book/eleanor-oliphant-is-completely-fine', 'book/Csontvaros', 1, 21, 1, '8012345678099124', NULL, 2, 3, 10),
(11, 'Magpie Murders', 'self-published', 14, NULL, '2024-03-09 15:34:29', 'When editor Susan Reyland is given the tattered manuscript of Alan Conway\'s latest novel, she has little idea it will change her life.', 4500, 'pictures/book/magpie-murders', 'book/Jenny_Han_-_A_fiuknak_akiket_valaha_szerettem', 1, 560, 1, '8012345678099125', NULL, 2, 3, 11),
(12, 'The Cruel Prince', 'published by', 19, 26, '2024-04-24 14:36:49', 'A fantasy novel written by Holly Black, follows Jude Duarte, a human living in Elfhame, a world with faerie\'s. Jude longs to be a knight, but her father forbids her. It is a story about overcoming discrimination, as Jude is often bullied by the King\'s children, and especially Prince Cardan.', 4500, 'pictures/book/the-cruel-prince', 'book/Jenny_Han_-_A_fiuknak_akiket_valaha_szerettem', 1, 428, 1, '8012345678099126', '236742529181653', 2, 3, 12),
(13, 'Believe Me', 'published by', 12, 21, '2023-10-04 14:39:02', 'A powerful, heartrending contemporary novel about fear, first love, and the devastating impact of prejudice. A heart wrenching novel about Shadi, a Muslim teen struggling to forge a blurry identity, fall in love, and find hope in the wake of 9/11.', 5000, 'pictures/book/believe-me', 'book/Jenny_Han_-_A_fiuknak_akiket_valaha_szerettem', 1, 224, 1, '8012345678099126', '5252433189962423', 2, 3, 13),
(14, 'Girl inPieces', 'published by', 12, 23, '2023-12-14 15:40:58', '“Girl in Pieces” introduces readers to Charlotte “Charlie” Davis, a 17-year-old girl grappling with intense trauma. Her journey is a poignant tale of pain, resilience, and the quest for healing.', 4500, 'pictures/book/girl-in-pieces', 'book/Jenny_Han_-_A_fiuknak_akiket_valaha_szerettem', 1, 448, 1, '8012345678099126', '46732874322', 2, 3, 15),
(15, 'Before the Coffee Gets Cold', 'looking for a publisher', 12, NULL, '2024-02-07 15:42:46', 'It tells of a café in Tokyo that allows its customers to travel back in time, as long as they return before their coffee gets cold. The story originally began as a play in 2010, before being adapted into a novel in 2015.', NULL, 'pictures/book/before-the-coffee-gets-cold', 'book/Jenny_Han_-_A_fiuknak_akiket_valaha_szerettem', 1, 272, 1, NULL, NULL, 2, 3, 16),
(16, 'Harmony', 'published by', 12, 24, '2024-04-17 14:46:27', 'In this collection of all new poems, Whitney Hanson explores the progression of a life through the lens of music. We each begin with a simple note, but as life progresses, we\'re led to the next note, and the next - all of which combine to form the melody of a song and the cadence of a life.', 6000, 'pictures/book/harmony', 'book/ally_carter-_ha_megtudnad_hogy_szeretlek_meg_kellene_oljelek', 1, 272, 0, '8012345678099111', '87235144441243', 2, 2, 17),
(17, 'The Silent Patient', 'looking for a publisher', 11, NULL, '2023-07-28 14:48:00', 'Theo Faber is a criminal psychotherapist who has waited a long time for the opportunity to work with Alicia. His determination to get her to talk and unravel the mystery of why she shot her husband takes him down a twisting path into his own motivations—a search for the truth that threatens to consume him....', NULL, 'pictures/book/the-silent-patient', 'book/ally_carter-_ha_megtudnad_hogy_szeretlek_meg_kellene_oljelek', 1, 352, 1, NULL, NULL, 2, 3, 18),
(18, 'Thin Skin', 'looking for a publisher', 11, NULL, '2023-08-26 14:50:42', 'Thin Skin uses her medical diagnosis as a prism to examine the thinning of boundaries between our bodies and the world:\" to be thin-skinned is to feel keenly, to percieve things that...\"', NULL, 'pictures/book/thin-skin', 'book/ally_carter-_ha_megtudnad_hogy_szeretlek_meg_kellene_oljelek', 1, 571, 1, NULL, NULL, 2, 3, 19),
(19, 'Happy Place', 'looking for a publisher', 11, NULL, '2023-12-15 15:52:47', '“Happy Place” follows ex-fiancés Harriet, a conflict-avoidant surgical resident, and Wyn, a quick-witted charmer who dances through life.', NULL, 'pictures/book/happy-place', 'book/ally_carter-_ha_megtudnad_hogy_szeretlek_meg_kellene_oljelek', 1, 416, 1, NULL, NULL, 2, 3, 20),
(20, 'The Fault in Our Stars', 'published by', 9, 30, '2024-04-02 14:55:53', 'The Fault in Our Stars by John Green is a young adult fiction novel that narrates the story of a 16-year-old girl who is diagnosed with cancer.', 6500, 'pictures/book/the-fault-in-our-stars', 'book/ally_carter-_ha_megtudnad_hogy_szeretlek_meg_kellene_oljelek', 1, 313, 1, '801232367802425', '24789354224455', 2, 3, 21),
(21, 'Holler, Child: Stories', 'self-published', 18, NULL, '2024-03-31 14:58:12', 'In “Holler, Child,” a mother is forced into an impossible position when her son gets in a kind of trouble she knows too well from the other side. And “Time After” shows us the unshakable bonds of family as a sister journeys to find her estranged brother—the one who saved her many times over.\r\n', 4200, 'pictures/book/holler-child-stories', 'book/ally_carter-_ha_megtudnad_hogy_szeretlek_meg_kellene_oljelek', 1, 563, 1, '801632367802425', NULL, 2, 3, 22),
(22, 'Wildfire', 'self-published', 18, NULL, '2024-04-26 15:04:59', 'A wildfire is an unplanned, unwanted fire burning in a natural area, such as a forest, grassland, or prairie. Wildfires can start from natural causes, such as lightning, but most are caused by humans, either accidentally or intentionally.', 4300, 'pictures/book/wildfire', 'book/Nelkuled_-_Leiner_Laura', 1, 400, 1, '801232877802425', NULL, 2, 3, 23),
(23, 'Mrs. Dalloway', 'published by', 1, 28, '2023-05-25 15:07:37', 'It examines one day in the life of Clarissa Dalloway, an upper-class Londoner married to a member of Parliament. Mrs. Dalloway is essentially plotless; what action there is takes place mainly in the characters\' consciousness.', 6000, 'pictures/book/mrs-dalloway', 'book/Nelkuled_-_Leiner_Laura', 1, 224, 1, '805332877802425', '5723145781237465324', 2, 3, 24),
(24, 'Man and Boy', 'published by', 15, 25, '2024-02-09 16:09:01', 'Man and Boy by Tony Parsons is the story of how a man becomes a father to his son, and a son to a father. The affection Harry feels for his family, all of it, is obvious from the first page. As evident is Harry\'s sense of self. He comes to realise that what he feels isn\'t always enough, though.', 6750, 'pictures/book/man-and-boy', 'book/Nelkuled_-_Leiner_Laura', 1, 356, 1, '801679462802425', '12345678-12345678-12345678', 2, 3, 25),
(25, 'The Wedding Date', 'self-published', 15, NULL, '2024-04-02 15:11:45', 'A groomsman and his last-minute guest are about to discover if a fake date can go the distance in a fun and flirty debut novel. Agreeing to go to a wedding with a guy she gets stuck with in an elevator is something Alexa Monroe wouldn\'t normally do. But there\'s something about Drew Nichols that\'s too hard to resist.', 4500, 'pictures/book/the-wedding-date', 'book/Nelkuled_-_Leiner_Laura', 1, 272, 1, '801679496302425', NULL, 2, 3, 23),
(26, 'Fourth Wing', 'self-published', 15, NULL, '2024-04-26 15:14:31', 'A young scribe is thrust into an elite war college for dragon riders where the only rule is graduate or perish. An addictive fantasy with epic levels of spice and world-building. Twenty-year-old Violet Sorrengail was supposed to enter the Scribe Quadrant, living a quiet life among books and history.', 5500, 'pictures/book/fourth-wing', 'book/Nelkuled_-_Leiner_Laura', 79, 528, 1, '801862877802425', NULL, 2, 3, 13),
(27, 'After', 'self-published', 15, NULL, '2024-04-26 15:14:31', 'The series follows the life of Tessa Young, a recent high school graduate, as she embarks on her new college life. Her life is meticulously planned by not only herself but her overachieving mother. But when Tessa meets complex rebel Hardin Scott, everything in her life begins to change.', 4200, 'pictures/book/after', 'book/a_mennyeknel_sulyosabb_', 1, 592, 1, '801462877802425', NULL, 2, 3, 23),
(28, 'Beyond the Horizon', 'self-published', 9, NULL, '2024-03-28 11:30:18', 'A first novel by a Ghanaian woman who spent some time in Germany. It provides an account of the exploitation of women in Africa and Europe, and tells of an immigrant who, having travelled to Germany to find a paradise, finds she has been betrayed by her husband and is forced into prostitution.', 4100, 'pictures/book/Beyond-the-Horizon', 'book/Bexi_Sorozat_3.-Illuzio', 0, 400, 1, '801687467802425', '', 2, 3, 1),
(29, 'Beyond the Veil', 'self-published', 1, NULL, '2023-06-14 10:31:04', 'Internationally renowned sociologist Fatema Mernissi argues that women\'s oppression is not due to Islam because this religion celebrates women\'s power. Women\'s oppression, she maintains, is due to political manipulation of religion by power-seeking, archaic Muslim male elites.', 3500, 'pictures/book/Beyond-the-Veil', 'book/Bexi_Sorozat_3.-Illuzio', 0, 365, 1, '801232877202425', NULL, 2, 3, 2),
(30, 'Chasing Echoes', 'looking for a publisher', 6, NULL, '2023-12-23 11:38:26', 'Chasing Echoes is the story of an extended (and dysfunctional) Jewish American family trying to track down their roots in Poland. Most of their relatives and history were wiped out by the Holocaust. Now they only have some stories from their grandfather and a few old pictures to go by.', NULL, 'pictures/book/Chasing-Echoes', 'book/Bexi_Sorozat_3.-Illuzio', 0, 1200, 1, NULL, NULL, 2, 3, 3),
(31, 'Kings of Chaos', 'looking for a publisher', 17, NULL, '2023-07-21 10:41:23', 'And I\'ve got demons of my own. Kings of Chaos is a full length dark new adult romance with enemies-to-lovers/love-hate themes, featuring a slightly psycho heroine and four even more psychotic men.', NULL, 'pictures/book/kings-of-chaos', 'book/Bexi_Sorozat_3.-Illuzio', 0, 484, 1, NULL, NULL, 2, 3, 4),
(32, 'Dreams of Destiny', 'published by', 14, 25, '2024-04-09 10:41:23', 'Dream of Destiny is a story of true love, betrayal, forgiveness and journey of self discovery, inspired by Hades & Persephone\'s myth. This modern retelling book is a dark, standalone book with adult themes, which some readers might find uncomfortable and triggering.', 4200, 'pictures/book/Dreams-of-Destiny', 'book/Bexi_Sorozat_3.-Illuzio', 0, 288, 1, '801462877802425', '801432877802425', 2, 3, 5),
(33, 'Revelations: A Nove', 'self-published', 13, NULL, '2024-02-15 11:49:32', 'Brings to vivid life Margery Kempe and her world with all its riotous color, conflicting religious beliefs, deadly perils, saints and sinners. Revelations is a fascinating journey into both the medieval world and the medieval mind.', 5000, 'pictures/book/revelations', 'book/SZJG-_6-_ketten', 0, 416, 1, '12345679876543234', NULL, 2, 3, 6),
(34, 'Echoes of Eternity', 'published by', 15, 28, '2024-02-07 11:49:32', 'Angron, Herald of Horus, has achieved immortality through annihilation – now he leads the armies of the damned in a wrathful tide, destroying all before them as the warp begins its poisonous corruption of Terra. For the Emperor\'s beleaguered forces, the end has come. The Khan lies on the edge of death.', 6300, 'pictures/book/Echoes-of-Eternity', 'book/SZJG-_6-_ketten', 0, 400, 1, '801122877802425', '801432823802425', 2, 3, 7),
(35, 'Legacy of Shadows', 'looking for a publisher', 18, NULL, '2023-04-27 10:56:42', 'All I wanted was to keep my head above water. To survive long enough to hit my eighteenth birthday so I could escape the nightmare that my homelife had become. But all of that was turned upside down the moment they showed up.\r\nThe best friend from my past. The surly brooder. The kind-hearted nerd. The king of campus. The dark one.\r\n', NULL, 'pictures/book/Legacy-of-Shadows', 'book/SZJG-_6-_ketten', 0, 288, 1, NULL, NULL, 2, 3, 8),
(36, 'The Sands of Time', 'self-published', 12, NULL, '2023-10-18 11:12:23', 'The novel follows the adventures of four women who are forced to leave their Spanish convent for the outside world of threat, violence and passions; and two men who are pitted against each other in a fight to the death.', 3540, 'pictures/book/Sands-of-Time', 'book/SZJG-_6-_ketten', 0, 412, 1, '801245277202425', NULL, 2, 3, 9),
(37, 'The Forgotten Scroll', 'looking for a publisher', 8, NULL, '2024-03-16 12:17:19', 'When thirteen-year-old Jaxon\'s father died, he thought all was lost, until he was taken to a new world. Living his whole life on a dying planet, he never imagined he would see trees, grass, or blue sky. He never even knew they even existed. Overjoyed at the possibility of a new life, Jaxon soon learns that it might not be possible after all.', NULL, 'pictures/book/The-Forgotten-Scroll', 'book/SZJG-_6-_ketten', 0, 173, 0, NULL, NULL, 2, 2, 10),
(38, 'Twisted Lve', 'published by', 19, 24, '2024-04-17 11:20:37', 'A scintillating romance about a cold-hearted man driven by vengeance whose heart starts to melt when he is forced to look after his best friend\'s sister, Twisted Love is essential reading for all fans of enemies-to-lovers stories. He has a heart of ice... but for her, he\'d burn the world.', 5300, 'pictures/book/twisted-love', 'book/SZJG-_6-_ketten', 0, 352, 1, '801234567002425', '801238167002425', 2, 3, 11),
(39, 'It Ends with Us', 'published by', 9, 21, '2024-03-08 12:25:57', 'This novel focuses on how harmful love can be, and how a person that loves you can hurt you the most. I read this novel during winter break, and all I can say is that it\'s very impacting and brings awareness to a lot of very sensitive topics.', 6000, 'pictures/book/it-ends-with-us', 'book/SZJG-_6-_ketten', 0, 421, 1, '801679462102425', '801238167002425', 2, 3, 12),
(40, 'King of Wrath', 'looking for a publisher', 14, NULL, '2024-02-24 12:25:57', 'King of Wrath is a steamy arranged marriage/billionaire romance. It is book one in the Kings of Sin series but can be read as a standalone. It contains explicit content, profanity, and mild violence. Recommended for mature readers only.', NULL, 'pictures/book/king-of-wrath', 'book/Leiner_Laura_-_A_Szent_Johanna_Gimi_8._-_Orokke_II.', 0, 400, 1, NULL, NULL, 2, 3, 13),
(41, 'The Wind in the Willows', 'self-published', 15, NULL, '2024-01-10 12:31:53', 'It details the story of Mole, Ratty, and Badger as they try to help Mr. Toad, after he becomes obsessed with motorcars and gets into trouble.', 3300, 'pictures/book/the-wind-in-the-willows', 'book/Leiner_Laura_-_A_Szent_Johanna_Gimi_8._-_Orokke_II.', 0, 192, 0, '801276367802425', NULL, 2, 1, 14),
(42, 'The Exchange: After The Firm', 'self-published', 11, NULL, '2023-08-16 11:31:53', 'Thid new book follows the story of Mitch McDeere from THE FIRM, 15 years after he and wife Abby escaped from the Chicago mob with their lives.', 3800, 'pictures/book/the-exchange-after-the-firm', 'book/Leiner_Laura_-_A_Szent_Johanna_Gimi_8._-_Orokke_II.', 0, 338, 1, '801469877802425', NULL, 2, 3, 15),
(43, 'Murtagh', 'looking for a publisher', 7, NULL, '2024-01-02 12:39:38', 'Join Dragon Rider—and fan favorite—Murtagh and his dragon as they confront a perilous new enemy! The world is no longer safe for the Dragon Rider Murtagh and his dragon, Thorn. An evil king has been toppled, and they are left to face the consequences of the reluctant role they played in his reign of terror.', NULL, 'pictures/book/murtagh', 'book/Leiner_Laura_-_A_Szent_Johanna_Gimi_8._-_Orokke_II.', 0, 704, 1, NULL, NULL, 2, 3, 16),
(44, 'The Ink Black Heart', 'self-published', 6, NULL, '2024-03-12 12:43:33', 'The Ink Black Heart is about the female creator of a popular YouTube cartoon who releases a cartoon criticized as being racist, ableist, and—you guessed it—transphobic.', 4800, 'pictures/book/the-ink-black-heart', 'book/Leiner_Laura_-_A_Szent_Johanna_Gimi_8._-_Orokke_II.', 0, 1024, 1, '801687167802425', NULL, 2, 3, 17),
(45, 'Harry Potter and the Philosopher\'s Stone', 'published by', 12, 26, '2024-04-28 11:54:08', 'Featuring vivid descriptions and an imaginative story line, it followed the adventures of the unlikely hero Harry Potter, a lonely orphan who discovers that he is actually a wizard and enrolls in the Hogwarts School of Witchcraft and Wizardry. The book received numerous awards, including the British Book Award.', 5500, 'pictures/book/harry-potter-1', 'book/Leiner_Laura_-_A_Szent_Johanna_Gimi_8._-_Orokke_II.', 0, 233, 0, '801687432402425', '2345763234676543210', 2, 2, 18),
(46, 'Game of Thrones', 'looking for a publisher', 14, NULL, '2024-03-17 12:54:57', 'Sweeping from a harsh land of cold to a summertime kingdom of epicurean plenty, A Game of Thrones tells a tale of lords and ladies, soldiers and sorcerers, assassins and bastards, who come together in a time of grim omens.', NULL, 'pictures/book/game-of-thrones', 'book/Leiner_Laura_-_A_Szent_Johanna_Gimi_8._-_Orokke_II.', 73, 694, 1, NULL, NULL, 2, 3, 19),
(47, 'A Clash of Kings', 'self-published', 1, NULL, '2023-04-12 12:01:31', 'A Clash of Kings depicts the Seven Kingdoms of Westeros in civil war, while the Night\'s Watch mounts a reconnaissance to investigate the mysterious people known as wildlings. Meanwhile, Daenerys Targaryen continues her plan to conquer the Seven Kingdoms.', 6500, 'pictures/book/clash-of-kings', 'book/Leiner_Laura_-_A_Szent_Johanna_Gimi_8._-_Orokke_II.', 70, 768, 1, '801462832402425', NULL, 2, 3, 20),
(48, 'A ​Storm of Swords: Steel and Snow', 'looking for a publisher', 5, NULL, '2024-03-26 13:04:14', 'A Storm of Swords continues the story where A Clash of Kings ended. The novel describes the increasingly vicious War of Five Kings in Westeros, Daenerys\'s strengthening forces in the East, and the oncoming threat of the Others, a ghostly army that is nearly invincible.', NULL, 'pictures/book/storm-of-swords', 'book/Leiner_Laura_-_A_Szent_Johanna_Gimi_8._-_Orokke_II.', 82, 9730, 1, NULL, NULL, 2, 3, 21),
(49, 'A Feast for Crows', 'looking for a publisher', 7, NULL, '2024-01-18 13:05:28', 'A Feast for Crows focuses on the Lannister family\'s continuing consolidation of power following victory in the “War of the Five Kings.” Specifically, it follows the events precipitated by the murder of Tywin Lannister, who had been de facto ruler of Westeros. In his place, his daughter Cersei, seizes power.', NULL, 'pictures/book/feast-for-crows', 'book/Nelkuled_-_Leiner_Laura', 46, 753, 1, NULL, NULL, 2, 3, 22),
(50, 'A Dance with Dragons', 'self-published', 9, NULL, '2024-03-26 13:11:56', 'In the aftermath of a colossal battle, the future of the Seven Kingdoms hangs in the balance—beset by newly emerging threats from every direction. In the east, Daenerys Targaryen, the last scion of House Targaryen, rules with her three dragons as queen of a city built on dust and death.', 7800, 'pictures/book/dance-with-the-dragons', 'book/Nelkuled_-_Leiner_Laura', 73, 1056, 1, '801232361302425', NULL, 2, 3, 23),
(51, 'Harry Potter and the Prisoner of Azkaban', 'looking for a publisher', 11, NULL, '2023-10-13 12:16:22', 'The book follows Harry Potter, a young wizard, in his third year at Hogwarts School of Witchcraft and Wizardry. Along with friends Ronald Weasley and Hermione Granger, Harry investigates Sirius Black, an escaped prisoner from Azkaban, the wizard prison, believed to be one of Lord Voldemort\'s old allies.', NULL, 'pictures/book/harry-potter-2', 'book/Jenny_Han_-_A_fiuknak_akiket_valaha_szerettem', 0, 448, 1, NULL, NULL, 2, 2, 24),
(52, 'A Good Girl\'s Guide to Murder Könyv', 'looking for a publisher', 18, NULL, '2024-04-03 12:16:22', 'A Good Girl\'s Guide to Murder is a YA mystery novel following high schooler Pippa Fitz-Amobi. What first started as a school project, Pippa begins to dig into the murder of high schooler Andie Bell, a case that occurred five years ago, in her small town. The case is apparently closed.', NULL, 'pictures/book/a-good-girls-guide-to-murder', 'book/Bexi_Sorozat_3.-Illuzio', 0, 432, 1, NULL, NULL, 2, 3, 25);

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

--
-- A tábla adatainak kiíratása `bookrating`
--

INSERT INTO `bookrating` (`id`, `ratingerId`, `bookId`, `rating`, `ratingTime`) VALUES
(1, 26, 1, 2, '2024-02-24 16:46:20'),
(2, 24, 1, 5, '2024-02-22 16:46:20'),
(3, 15, 1, 4, '2024-04-02 15:48:34'),
(4, 9, 1, 4, '2024-04-08 15:48:34'),
(5, 21, 2, 1, '2024-02-26 16:50:26'),
(6, 29, 2, 5, '2024-03-06 16:50:57'),
(7, 6, 2, 4, '2024-04-15 15:50:57'),
(8, 12, 2, 5, '2024-03-20 16:51:45'),
(9, 1, 2, 2, '2024-04-10 15:51:45'),
(10, 5, 2, 5, '2024-02-29 16:52:21'),
(11, 22, 2, 3, '2024-04-17 15:52:21'),
(12, 11, 2, 4, '2024-02-26 16:53:44'),
(13, 13, 2, 1, '2024-04-08 15:53:44'),
(14, 8, 2, 3, '2024-03-11 16:54:36'),
(15, 19, 2, 2, '2024-03-30 16:54:36'),
(16, 18, 2, 1, '2024-03-09 16:55:38'),
(17, 28, 3, 4, '2024-04-11 15:56:22'),
(18, 15, 3, 5, '2024-04-12 15:56:53'),
(19, 5, 3, 1, '2024-04-11 15:56:53'),
(20, 18, 3, 2, '2024-04-19 15:57:36'),
(21, 11, 3, 5, '2024-04-24 15:57:37'),
(22, 21, 3, 3, '2024-04-22 15:58:47'),
(23, 14, 3, 5, '2024-04-24 15:58:47'),
(24, 29, 3, 4, '2024-04-15 15:59:31'),
(25, 6, 3, 1, '2024-04-09 15:59:31'),
(26, 8, 3, 4, '2024-04-25 16:00:36'),
(27, 28, 3, 2, '2024-04-16 16:00:36'),
(28, 21, 4, 3, '2024-02-29 17:04:01'),
(29, 26, 4, 2, '2024-04-09 16:04:01'),
(30, 18, 4, 5, '2024-03-13 17:05:12'),
(31, 29, 4, 2, '2024-04-22 16:05:12'),
(32, 15, 4, 4, '2024-04-10 16:06:05'),
(33, 1, 4, 3, '2024-03-20 17:06:05'),
(34, 11, 4, 1, '2024-04-13 16:06:51'),
(35, 19, 4, 2, '2024-04-09 16:06:51'),
(36, 7, 4, 4, '2024-04-24 16:08:03'),
(37, 14, 5, 5, '2024-04-02 16:09:28'),
(38, 29, 5, 3, '2024-04-11 16:09:28'),
(39, 28, 5, 1, '2024-04-10 16:10:48'),
(40, 13, 5, 3, '2024-04-22 16:10:48'),
(41, 24, 5, 2, '2024-04-08 16:11:19'),
(42, 15, 5, 1, '2024-04-20 16:11:19'),
(43, 17, 5, 3, '2024-04-16 16:11:59'),
(44, 7, 6, 1, '2024-03-30 17:12:22'),
(45, 15, 6, 2, '2024-04-03 16:12:22'),
(46, 26, 6, 5, '2024-04-22 16:13:11'),
(47, 19, 6, 4, '2024-04-20 16:13:11'),
(48, 6, 7, 5, '2024-04-06 16:13:46'),
(49, 22, 7, 2, '2024-04-17 16:13:46'),
(50, 19, 7, 4, '2024-04-17 16:14:33'),
(51, 17, 7, 3, '2024-04-16 16:14:33'),
(52, 27, 7, 5, '2024-04-22 16:15:14'),
(53, 11, 7, 5, '2024-04-17 16:15:14'),
(54, 15, 7, 4, '2024-04-23 16:15:48'),
(55, 21, 7, 5, '2024-04-20 16:15:48'),
(56, 24, 7, 3, '2024-04-07 16:16:46'),
(57, 5, 7, 5, '2024-04-10 16:16:46'),
(58, 12, 7, 4, '2024-04-09 16:17:10'),
(59, 1, 8, 3, '2024-04-18 16:17:45'),
(60, 8, 8, 4, '2024-04-25 16:17:45'),
(61, 12, 8, 2, '2024-04-22 16:18:43'),
(62, 27, 8, 5, '2024-04-19 16:18:43'),
(63, 5, 8, 4, '2024-04-18 16:34:15'),
(64, 26, 8, 1, '2024-04-20 16:34:15'),
(65, 15, 8, 2, '2024-04-24 16:35:09'),
(66, 19, 8, 1, '2024-04-22 16:35:09'),
(67, 24, 8, 2, '2024-04-22 16:35:48'),
(68, 25, 8, 4, '2024-04-20 16:35:48'),
(69, 11, 8, 3, '2024-04-22 16:36:33'),
(70, 28, 8, 4, '2024-04-20 16:36:33'),
(71, 7, 8, 2, '2024-04-18 16:37:32'),
(72, 13, 8, 4, '2024-04-25 16:37:32'),
(73, 23, 9, 1, '2024-02-28 17:40:14'),
(74, 25, 9, 2, '2024-03-13 17:40:14'),
(75, 28, 9, 3, '2024-04-10 16:41:33'),
(76, 11, 9, 2, '2024-03-09 17:41:33'),
(77, 1, 9, 1, '2024-04-17 16:41:54'),
(78, 19, 9, 3, '2024-03-19 17:41:54'),
(79, 6, 9, 1, '2024-02-28 17:42:16'),
(80, 22, 10, 3, '2024-02-28 17:42:29'),
(81, 8, 10, 5, '2024-02-27 17:42:29'),
(82, 15, 10, 4, '2024-03-20 17:44:37'),
(83, 19, 10, 5, '2024-04-10 16:44:37'),
(84, 29, 10, 4, '2024-03-19 17:44:58'),
(85, 18, 10, 2, '2024-04-01 16:44:58'),
(86, 30, 10, 3, '2024-04-08 16:45:16'),
(87, 1, 10, 5, '2024-04-06 16:45:16'),
(88, 26, 10, 2, '2024-03-13 17:45:41'),
(89, 5, 10, 5, '2024-04-25 16:45:41'),
(90, 17, 10, 2, '2024-03-07 17:45:58'),
(91, 7, 10, 5, '2024-03-27 17:45:58'),
(92, 27, 11, 4, '2024-03-11 17:46:23'),
(93, 6, 11, 3, '2024-03-28 17:46:23'),
(94, 5, 11, 1, '2024-04-09 16:47:31'),
(95, 25, 11, 3, '2024-04-05 16:47:31'),
(96, 8, 11, 4, '2024-03-20 17:47:49'),
(97, 19, 11, 5, '2024-03-16 17:47:49'),
(98, 13, 12, 2, '2024-04-25 16:48:11'),
(99, 28, 12, 4, '2024-04-25 16:48:11'),
(100, 19, 13, 5, '2023-10-06 16:49:03'),
(101, 26, 13, 4, '2024-01-16 17:49:03'),
(102, 9, 13, 3, '2024-01-19 17:51:20'),
(103, 1, 13, 4, '2024-04-07 16:51:20'),
(104, 21, 13, 5, '2024-02-02 17:51:44'),
(105, 27, 13, 2, '2024-03-12 17:51:44'),
(106, 6, 13, 3, '2024-04-01 16:52:09'),
(107, 7, 13, 1, '2024-01-19 17:52:09'),
(108, 28, 13, 3, '2023-12-01 17:52:32'),
(109, 18, 13, 1, '2023-11-25 17:52:32'),
(110, 11, 13, 4, '2024-02-12 17:53:01'),
(111, 14, 13, 1, '2024-01-16 17:53:01'),
(112, 13, 13, 4, '2024-01-16 17:53:27'),
(113, 16, 14, 3, '2024-02-06 17:53:43'),
(114, 13, 14, 5, '2024-01-19 17:53:43'),
(115, 11, 14, 1, '2024-04-15 16:54:31'),
(116, 28, 15, 2, '2024-02-10 17:54:47'),
(117, 9, 15, 4, '2024-02-21 17:54:47'),
(118, 13, 15, 5, '2024-03-16 17:55:49'),
(119, 23, 15, 1, '2024-04-08 16:55:49'),
(120, 19, 15, 2, '2024-03-02 17:56:16'),
(121, 29, 16, 5, '2024-02-20 17:57:06'),
(122, 30, 16, 1, '2024-03-06 17:57:06'),
(123, 11, 16, 3, '2024-03-06 17:57:47'),
(124, 23, 16, 2, '2024-04-09 16:57:47'),
(125, 13, 16, 1, '2024-02-29 17:58:08'),
(126, 1, 16, 3, '2024-04-09 16:58:08'),
(127, 18, 17, 5, '2023-07-30 17:00:46'),
(128, 9, 17, 1, '2023-08-02 17:00:46'),
(129, 17, 17, 2, '2023-11-07 18:03:10'),
(130, 27, 17, 5, '2023-10-17 17:03:10'),
(131, 8, 17, 4, '2024-04-23 17:03:41'),
(132, 24, 17, 5, '2024-02-21 18:03:41'),
(133, 23, 17, 2, '2023-12-22 18:04:03'),
(134, 12, 17, 1, '2023-12-29 18:04:03'),
(135, 15, 17, 5, '2024-02-22 18:04:30'),
(136, 1, 17, 5, '2023-09-30 17:04:30'),
(137, 28, 17, 3, '2024-02-16 18:04:54'),
(138, 11, 18, 2, '2023-08-23 17:05:03'),
(139, 6, 18, 5, '2023-12-21 18:05:03'),
(140, 5, 18, 2, '2024-04-07 17:06:40'),
(141, 23, 18, 5, '2024-02-23 18:06:40'),
(142, 25, 18, 4, '2023-11-22 18:07:03'),
(143, 30, 18, 2, '2023-12-14 18:07:03'),
(144, 29, 18, 4, '2023-11-25 18:07:38'),
(145, 1, 18, 1, '2023-08-30 17:07:38'),
(146, 13, 18, 2, '2024-04-23 17:08:25'),
(147, 7, 18, 5, '2024-03-13 18:08:25'),
(148, 15, 19, 4, '2024-01-17 18:08:47'),
(149, 30, 19, 5, '2023-12-29 18:08:47'),
(150, 25, 19, 4, '2024-04-16 17:09:44'),
(151, 15, 19, 5, '2024-03-19 18:09:44'),
(152, 18, 20, 5, '2024-04-09 17:10:08'),
(153, 7, 20, 4, '2024-04-19 17:10:08'),
(154, 19, 21, 1, '2024-04-01 17:10:43'),
(155, 26, 21, 4, '2024-04-03 17:10:43'),
(156, 15, 21, 2, '2024-04-15 17:11:29'),
(157, 6, 23, 3, '2023-05-17 17:12:38'),
(158, 21, 23, 3, '2023-05-27 17:12:38'),
(159, 9, 23, 1, '2023-08-16 17:13:50'),
(160, 29, 23, 3, '2023-05-31 17:13:50'),
(161, 27, 23, 5, '2023-12-20 18:14:16'),
(162, 8, 23, 2, '2023-11-15 18:14:16'),
(163, 22, 23, 3, '2023-09-23 17:14:40'),
(164, 7, 23, 1, '2023-10-18 17:14:40'),
(165, 17, 24, 2, '2024-02-15 18:15:23'),
(166, 28, 24, 4, '2024-02-29 18:15:23'),
(167, 18, 24, 5, '2024-03-21 18:16:33'),
(168, 12, 24, 2, '2024-03-01 18:16:33'),
(169, 11, 25, 3, '2024-04-03 17:17:06'),
(170, 9, 25, 5, '2024-04-10 17:17:06'),
(171, 29, 25, 1, '2024-04-10 17:17:50'),
(172, 8, 32, 5, '2024-04-17 15:32:24'),
(173, 22, 41, 2, '2024-04-02 15:32:24'),
(174, 14, 49, 5, '2024-02-22 16:34:24'),
(175, 19, 35, 1, '2024-04-23 15:34:24'),
(176, 7, 40, 5, '2024-04-02 15:34:54'),
(177, 1, 51, 3, '2024-02-14 16:34:54'),
(178, 14, 30, 1, '2024-01-04 16:35:48'),
(179, 17, 47, 5, '2024-04-18 15:35:48'),
(180, 6, 46, 2, '2024-02-29 16:36:37'),
(181, 8, 38, 1, '2024-04-25 15:36:37'),
(182, 9, 38, 5, '2024-04-24 15:37:52'),
(183, 21, 45, 3, '2024-04-28 15:38:50'),
(184, 8, 44, 4, '2024-03-15 16:38:51'),
(185, 30, 48, 5, '2024-03-28 16:38:51'),
(186, 14, 31, 1, '2024-01-18 16:46:26'),
(187, 23, 28, 5, '2024-03-30 16:46:26'),
(188, 22, 32, 3, '2024-04-17 16:04:31'),
(189, 27, 39, 4, '2024-03-09 17:04:31'),
(190, 25, 30, 1, '2024-02-06 17:05:51'),
(191, 5, 29, 5, '2024-04-11 16:05:51'),
(192, 19, 29, 3, '2023-09-19 16:07:01'),
(193, 7, 37, 5, '2024-03-18 17:07:01'),
(194, 22, 43, 1, '2024-02-08 17:08:43'),
(195, 7, 36, 3, '2023-11-01 17:08:43'),
(196, 12, 33, 2, '2024-03-06 17:09:31'),
(197, 13, 50, 5, '2024-04-17 16:09:31'),
(198, 15, 52, 4, '2024-04-17 16:11:42'),
(199, 25, 37, 3, '2024-03-21 17:11:42');

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

--
-- A tábla adatainak kiíratása `bookshopping`
--

INSERT INTO `bookshopping` (`id`, `userId`, `bookId`, `shoppingTime`) VALUES
(1, 1, 13, '2024-02-06 18:24:59'),
(2, 9, 25, '2024-04-10 17:24:59'),
(3, 13, 14, '2024-01-19 18:25:27'),
(4, 13, 15, '2024-03-07 18:25:27'),
(5, 5, 7, '2024-04-19 17:25:55'),
(6, 11, 49, '2024-02-03 17:13:17'),
(7, 17, 50, '2024-04-01 16:13:17'),
(8, 6, 32, '2024-04-11 16:14:04'),
(9, 11, 49, '2024-02-09 17:14:04'),
(10, 1, 38, '2024-04-22 16:14:58'),
(11, 8, 35, '2024-04-27 16:14:58'),
(12, 7, 28, '2024-04-04 16:15:56'),
(13, 17, 49, '2024-02-01 17:15:56'),
(14, 32, 1, '2024-05-01 05:36:29'),
(16, 1, 1, '2024-05-01 05:43:12');

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

--
-- A tábla adatainak kiíratása `categoryinterest`
--

INSERT INTO `categoryinterest` (`id`, `userId`, `categoryId`) VALUES
(1, 1, 1),
(2, 1, 6),
(3, 1, 8),
(4, 5, 4),
(5, 5, 7),
(6, 5, 3),
(7, 5, 15),
(8, 5, 23),
(9, 6, 9),
(10, 6, 13),
(11, 6, 21),
(12, 6, 25),
(13, 6, 29),
(14, 7, 2),
(15, 7, 14),
(16, 7, 10),
(17, 7, 32),
(18, 8, 13),
(19, 8, 12),
(20, 8, 11),
(21, 8, 9),
(22, 8, 19),
(23, 8, 21),
(24, 8, 30),
(25, 9, 4),
(26, 9, 8),
(27, 9, 7),
(28, 9, 27),
(29, 11, 22),
(30, 11, 23),
(31, 11, 24),
(32, 11, 27),
(33, 11, 31),
(34, 12, 2),
(35, 12, 13),
(36, 12, 12),
(37, 12, 23),
(38, 12, 21),
(39, 12, 31),
(40, 13, 4),
(41, 13, 8),
(42, 13, 7),
(43, 13, 9),
(44, 13, 12),
(45, 13, 19),
(46, 14, 2),
(47, 14, 27),
(48, 14, 26),
(49, 14, 29),
(50, 14, 30),
(51, 15, 4),
(52, 15, 8),
(53, 15, 20),
(54, 15, 17),
(55, 15, 25),
(56, 17, 13),
(57, 17, 11),
(58, 17, 10),
(59, 17, 9),
(60, 17, 21),
(61, 17, 24),
(62, 17, 33),
(63, 19, 4),
(64, 19, 7),
(65, 19, 8),
(66, 19, 10),
(67, 19, 9),
(68, 19, 11),
(69, 19, 15),
(70, 19, 14),
(71, 19, 27),
(72, 18, 6),
(73, 18, 12),
(74, 18, 16),
(75, 18, 17),
(76, 18, 28),
(77, 21, 6),
(78, 21, 10),
(79, 21, 12),
(80, 21, 7),
(81, 21, 8),
(82, 21, 20),
(83, 22, 1),
(84, 22, 8),
(85, 22, 4),
(86, 22, 3),
(87, 22, 7),
(88, 22, 2),
(89, 22, 6),
(90, 22, 21),
(91, 22, 26),
(92, 22, 25),
(93, 22, 22),
(94, 23, 26),
(95, 23, 27),
(96, 23, 28),
(97, 23, 24),
(98, 23, 23),
(99, 23, 22),
(100, 23, 17),
(101, 23, 18),
(102, 23, 19),
(103, 23, 20),
(104, 23, 6),
(105, 23, 29),
(106, 23, 30),
(107, 24, 3),
(108, 24, 2),
(109, 24, 6),
(110, 24, 8),
(111, 24, 15),
(112, 24, 18),
(113, 24, 19),
(114, 24, 17),
(115, 24, 13),
(116, 24, 20),
(117, 24, 23),
(118, 24, 24),
(119, 24, 22),
(120, 24, 21),
(121, 24, 26),
(122, 25, 13),
(123, 25, 18),
(124, 25, 20),
(125, 25, 23),
(126, 25, 24),
(127, 25, 22),
(128, 25, 21),
(129, 25, 25),
(130, 25, 26),
(131, 25, 27),
(132, 25, 28),
(133, 26, 3),
(134, 26, 2),
(135, 26, 1),
(136, 26, 6),
(137, 26, 8),
(138, 26, 23),
(139, 26, 22),
(140, 26, 31),
(141, 26, 29),
(142, 27, 3),
(143, 27, 27),
(144, 27, 26),
(145, 27, 25),
(146, 27, 29),
(147, 27, 30),
(148, 27, 31),
(149, 27, 22),
(150, 27, 21),
(151, 27, 23),
(152, 27, 24),
(153, 28, 6),
(154, 28, 7),
(155, 28, 11),
(156, 28, 14),
(157, 28, 15),
(158, 28, 13),
(159, 28, 30),
(160, 29, 1),
(161, 29, 7),
(162, 29, 8),
(163, 29, 15),
(164, 29, 16),
(165, 29, 18),
(166, 29, 19),
(167, 29, 22),
(168, 29, 21),
(169, 29, 23),
(170, 29, 24),
(171, 30, 6),
(172, 30, 15),
(173, 30, 14),
(174, 30, 13),
(175, 30, 9),
(176, 30, 18),
(177, 30, 21),
(178, 30, 23),
(179, 30, 22),
(180, 30, 24),
(181, 30, 26),
(182, 32, 1),
(183, 32, 2),
(184, 32, 3),
(185, 33, 14),
(186, 33, 18),
(187, 33, 20),
(188, 33, 27),
(189, 33, 29),
(190, 33, 33),
(191, 33, 32),
(192, 33, 31),
(193, 33, 30);

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
(25, '#d0a65d'),
(26, '#563d7c'),
(27, '#b3c14e'),
(28, '#429e87'),
(29, '#d72d2d'),
(30, '#538eac'),
(31, '#c969c6'),
(32, '#f0568c'),
(33, '#537474'),
(34, '#516a48'),
(35, '#b3c76b'),
(36, '#384394'),
(37, '#3d7b66'),
(38, '#319642'),
(39, '#58b0c6'),
(40, '#40c473'),
(41, '#bd4ca5'),
(42, '#5dadd0'),
(43, '#7b3d3d'),
(44, '#251986'),
(45, '#4d7b3d'),
(46, '#3d667b');

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

--
-- A tábla adatainak kiíratása `follow`
--

INSERT INTO `follow` (`id`, `followerId`, `followedId`, `followingTime`) VALUES
(1, 26, 9, '2024-03-28 17:54:09'),
(2, 21, 1, '2023-02-08 17:43:10'),
(3, 21, 15, '2023-12-12 17:43:10'),
(4, 21, 14, '2024-02-22 17:44:35'),
(5, 22, 5, '2024-02-08 17:45:06'),
(6, 22, 6, '2023-10-11 16:45:06'),
(7, 22, 11, '2023-06-15 16:46:42'),
(8, 23, 7, '2023-10-10 16:47:01'),
(9, 23, 8, '2023-12-13 17:47:01'),
(10, 23, 15, '2024-01-10 17:48:44'),
(11, 23, 19, '2024-04-23 16:48:44'),
(12, 24, 5, '2024-03-13 17:49:25'),
(13, 24, 8, '2023-11-16 17:49:25'),
(14, 24, 15, '2023-12-22 17:51:01'),
(15, 25, 15, '2023-12-29 17:51:38'),
(16, 25, 18, '2024-04-02 16:51:38'),
(17, 25, 19, '2024-04-24 16:53:29'),
(18, 25, 13, '2024-02-06 17:53:29'),
(19, 26, 17, '2023-08-16 16:54:09'),
(27, 26, 13, '2023-11-23 17:56:12'),
(28, 27, 15, '2024-04-01 16:56:41'),
(29, 27, 8, '2024-03-27 17:56:41'),
(30, 27, 6, '2023-11-22 17:58:22'),
(31, 28, 8, '2023-11-30 18:00:24'),
(32, 28, 13, '2024-02-08 18:00:24'),
(33, 28, 18, '2024-04-02 17:00:57'),
(34, 28, 19, '2024-04-25 17:00:57'),
(35, 29, 5, '2024-03-03 18:01:23'),
(36, 29, 1, '2023-08-01 17:01:23'),
(37, 29, 6, '2024-01-22 18:02:59'),
(38, 29, 11, '2023-09-04 17:02:59'),
(39, 29, 17, '2023-12-05 18:03:33'),
(40, 29, 18, '2024-04-01 17:03:33'),
(41, 30, 13, '2024-01-05 18:04:00'),
(42, 30, 1, '2023-05-04 17:04:00'),
(43, 30, 15, '2024-01-03 18:04:54'),
(44, 30, 17, '2023-09-14 17:04:54'),
(45, 1, 6, '2023-12-29 18:05:50'),
(46, 1, 13, '2024-02-15 18:05:50'),
(47, 1, 9, '2024-04-19 17:08:33'),
(48, 1, 15, '2023-12-21 18:08:33'),
(49, 5, 9, '2024-03-21 18:09:55'),
(50, 5, 18, '2024-04-10 17:10:10'),
(51, 5, 19, '2024-04-20 17:10:10'),
(52, 6, 8, '2024-01-15 18:10:42'),
(53, 6, 14, '2024-03-25 18:10:42'),
(54, 7, 18, '2024-03-28 18:11:52'),
(55, 7, 14, '2024-02-29 18:11:52'),
(56, 7, 13, '2024-02-16 18:13:20'),
(57, 8, 9, '2024-03-20 18:13:36'),
(58, 8, 5, '2024-04-08 17:13:36'),
(59, 8, 19, '2024-04-22 17:15:24'),
(60, 8, 15, '2024-01-24 18:15:24'),
(61, 9, 18, '2024-04-14 17:16:40'),
(62, 9, 19, '2024-04-20 17:16:40'),
(63, 11, 15, '2024-03-30 18:17:03'),
(64, 11, 6, '2023-12-15 18:17:03'),
(65, 11, 19, '2024-04-23 17:19:34'),
(66, 11, 7, '2023-12-09 18:19:34'),
(67, 12, 8, '2023-11-24 18:20:22'),
(68, 12, 14, '2024-02-22 18:20:22'),
(69, 12, 13, '2024-03-29 18:22:52'),
(70, 12, 6, '2023-11-23 18:22:52'),
(71, 13, 14, '2024-04-02 17:24:15'),
(72, 13, 5, '2024-02-21 18:24:15'),
(73, 13, 9, '2024-03-08 18:25:25'),
(74, 13, 19, '2024-04-18 17:25:25'),
(75, 14, 5, '2024-04-15 17:25:46'),
(76, 14, 18, '2024-03-31 17:25:46'),
(77, 14, 9, '2024-03-16 18:26:36'),
(78, 15, 13, '2024-02-02 18:26:48'),
(79, 15, 19, '2024-04-20 17:26:48'),
(80, 15, 14, '2024-03-09 18:27:43'),
(81, 17, 12, '2023-10-25 17:27:59'),
(82, 17, 7, '2023-11-17 18:27:59'),
(83, 17, 8, '2023-11-25 18:30:21'),
(84, 17, 6, '2023-12-11 18:30:21'),
(85, 18, 19, '2024-04-02 17:30:48'),
(86, 1, 28, '2023-11-17 19:40:59'),
(87, 1, 25, '2024-03-12 19:40:59'),
(88, 1, 27, '2023-11-16 19:43:26'),
(89, 5, 23, '2023-08-17 18:45:26'),
(90, 5, 30, '2023-04-22 18:45:26'),
(91, 5, 25, '2023-09-09 18:45:57'),
(92, 5, 26, '2023-04-13 18:45:57'),
(93, 6, 21, '2023-02-16 19:46:22'),
(94, 6, 28, '2024-01-12 19:46:22'),
(95, 6, 26, '2023-05-12 18:47:29'),
(96, 7, 22, '2023-09-25 18:47:47'),
(97, 7, 30, '2023-10-27 18:47:47'),
(98, 7, 28, '2024-02-16 19:48:58'),
(99, 7, 24, '2023-07-29 18:48:58'),
(100, 8, 23, '2023-08-19 18:49:27'),
(101, 8, 25, '2024-03-22 19:49:27'),
(102, 9, 27, '2023-11-16 19:50:14'),
(103, 9, 25, '2023-11-17 19:50:14'),
(104, 9, 24, '2023-12-09 19:52:02'),
(105, 9, 21, '2023-01-28 19:52:02'),
(106, 11, 26, '2023-08-10 18:52:30'),
(107, 11, 28, '2023-12-23 19:52:30'),
(108, 11, 29, '2023-04-29 18:55:07'),
(109, 12, 21, '2023-06-13 18:55:23'),
(110, 11, 22, '2023-06-29 18:55:23'),
(111, 13, 25, '2024-04-03 18:56:14'),
(112, 13, 27, '2023-09-30 18:56:14'),
(113, 14, 23, '2023-11-30 19:56:59'),
(114, 14, 28, '2023-12-14 19:56:59'),
(115, 15, 25, '2024-03-21 19:58:01'),
(116, 15, 24, '2023-11-30 19:58:01'),
(117, 15, 30, '2024-04-17 18:58:56'),
(118, 15, 27, '2023-12-15 19:58:56'),
(119, 17, 22, '2023-08-31 18:59:24'),
(120, 17, 21, '2023-03-25 19:59:24'),
(121, 17, 26, '2023-05-18 19:00:18'),
(122, 18, 29, '2023-05-24 19:00:37'),
(123, 18, 23, '2024-02-16 20:00:37'),
(124, 18, 27, '2023-11-10 20:01:36'),
(125, 19, 28, '2024-01-10 20:01:53'),
(126, 19, 22, '2023-05-26 19:01:53'),
(127, 19, 24, '2023-12-23 20:02:49'),
(128, 19, 26, '2023-04-20 19:02:49');

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

--
-- A tábla adatainak kiíratása `general`
--

INSERT INTO `general` (`id`, `birthdate`) VALUES
(1, '1985-07-15'),
(2, '1990-04-02'),
(3, '1988-12-10'),
(4, '1983-09-25'),
(5, '2000-03-11'),
(6, '1999-12-02'),
(7, '1989-11-03'),
(8, '1991-12-12'),
(9, '1987-05-12'),
(10, '1994-06-06'),
(11, '1991-09-08'),
(12, '1982-11-02'),
(13, '1999-01-22'),
(14, '1990-03-21'),
(15, '2001-02-01'),
(16, '2003-03-21'),
(17, '1994-07-22'),
(18, '1990-08-17'),
(19, '1981-05-30'),
(20, '2000-02-12'),
(21, '2002-11-14'),
(22, '2009-04-23');

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

--
-- A tábla adatainak kiíratása `post`
--

INSERT INTO `post` (`id`, `userId`, `description`, `postTime`) VALUES
(1, 1, 'Just finished the final chapter of my latest novel! Can\'t wait for you all to read it. #WritingCommunity #NewBook', '2023-05-25 15:40:41'),
(2, 1, 'Struggling with writer\'s block today. Any tips to get the creativity flowing again? #WritersLife #AmWriting', '2023-08-09 15:40:53'),
(3, 5, 'Just finished the first draft of my new novel! Celebrating with a cup of tea and some well-deserved relaxation. #FirstDraft #WritingLife', '2024-02-10 16:43:13'),
(4, 5, 'Exploring the complexities of human emotions in my latest short story. What themes do you enjoy exploring in your writing? #WritingCraft #Emotions', '2024-02-12 16:43:28'),
(5, 5, 'Reflecting on the power of storytelling to connect people from different walks of life. #WritingCommunity #Storytelling', '2024-02-20 16:43:41'),
(7, 6, 'Shoutout to my favorite authors who inspire me every day to keep writing and dreaming big. Who are your literary heroes? #WritingInspiration #Authors', '2023-10-22 15:46:01'),
(8, 7, 'In the midst of revisions and loving the opportunity to polish my manuscript until it shines. ', '2023-10-09 15:47:53'),
(9, 7, 'Embarking on a world-building journey today. Building immersive settings is one of my favorite parts of writing fantasy. ', '2023-11-05 16:48:03'),
(10, 7, 'Diving into a new genre this week and challenging myself as a writer. Who else loves pushing their boundaries?', '2023-11-20 16:48:14'),
(11, 8, 'Taking a break from writing to recharge my creative batteries. Sometimes a walk in nature is all it takes.', '2024-01-08 16:50:18'),
(12, 8, 'Just hit 50,000 words in my latest manuscript! Halfway there and feeling unstoppable.', '2024-03-25 16:50:30'),
(13, 9, 'Finding inspiration in unexpected places today. It\'s amazing where a chance encounter or a fleeting thought can lead.', '2024-04-05 15:51:39'),
(14, 11, 'Just hit a major plot twist in my current manuscript! Can\'t wait to see how my characters navigate through it.', '2023-07-20 15:52:53'),
(15, 11, 'Lost in the world of my own creation today. There\'s nothing quite like the feeling of immersing yourself in a story you\'ve written.', '2023-09-11 15:53:11'),
(16, 12, 'Reflecting on the power of storytelling to shape our understanding of the world. ', '2023-08-15 15:54:24'),
(17, 12, 'Exploring themes of identity and belonging in my latest project. What themes resonate with you as a reader?', '2023-10-10 15:54:37'),
(18, 13, 'Just received the first proofs of my upcoming book! Excited to see it all coming together. ', '2024-01-29 16:56:01'),
(19, 13, 'Taking a moment to appreciate the support of my fellow writers and readers. You make this journey worthwhile.', '2024-02-15 16:56:10'),
(20, 14, 'Lost in the world of my imagination today. Writing has a way of transporting us to places we\'ve never been. ', '2024-02-15 16:57:24'),
(21, 14, 'Struggling with the dreaded writer\'s block today. Time for a change of scenery and some fresh inspiration.', '2024-03-05 16:57:36'),
(22, 15, 'Juggling multiple projects at once and loving the creative challenge. Who else thrives on a bit of chaos?', '2023-12-15 16:58:51'),
(23, 15, 'Sharing a sneak peek of a new character I\'m introducing in my latest manuscript. Excited to see how they develop.', '2024-01-10 16:59:05'),
(24, 17, 'Just stumbled upon an old notebook filled with story ideas. Sometimes the best inspiration comes from the past.', '2023-07-10 16:00:34'),
(25, 18, 'Embracing the editing process today - every revision brings the story closer to its full potential.', '2024-03-29 17:01:52'),
(26, 18, 'Taking a break to immerse myself in a good book. Writers need to be readers too. ', '2024-04-10 16:02:06'),
(28, 19, 'Diving deep into research today. The more I learn, the richer my stories become. ', '2024-04-23 16:04:17'),
(29, 21, 'Calling all aspiring authors! Bright Publications is now accepting submissions for our upcoming anthology. Submit your stories today! ', '2023-04-30 16:06:33'),
(30, 22, 'Behind the scenes at Stellar Press: our dedicated team working hard to bring you the next literary masterpiece.', '2023-07-05 16:07:46'),
(31, 22, 'Join us tonight for a live Q&A session with bestselling author Emily Johnson. Get insights into her writing process and ask your burning questions! ', '2024-01-10 17:08:01'),
(32, 23, 'Embark on a journey through the pages of our latest releases. From romance to mystery, there\'s something for every reader at Horizon Books.', '2023-07-28 16:09:00'),
(33, 23, 'Stay tuned for exciting news about our upcoming book club! Connect with fellow book lovers and dive into engaging discussions about your favorite reads.', '2023-08-08 16:09:13'),
(34, 24, 'At Evergreen Publishing, we\'re committed to sustainability. Discover our eco-friendly printing practices and our dedication to preserving the environment.', '2023-09-21 16:10:43'),
(35, 24, 'Join us in celebrating National Book Lovers Day! Share your favorite book recommendations and spread the joy of reading.', '2024-04-23 16:10:59'),
(36, 25, 'Calling all fantasy fans! Dive into a world of magic and wonder with our latest fantasy releases. Let your imagination take flight!', '2023-10-21 16:12:29'),
(37, 27, 'Silverleaf Publishers - where stories shine bright like silver. Discover your next literary treasure among our curated selection of books.', '2023-10-28 16:13:28'),
(38, 27, 'Join us in supporting independent bookstores! Local bookshops are the heart and soul of the literary community.', '2023-11-13 17:13:38'),
(39, 27, 'Behind every great book is a great editor. Meet the talented individuals who help bring our authors\' visions to life. ', '2024-01-10 17:13:48'),
(40, 28, 'Uncover the secrets of successful storytelling with our upcoming masterclass series. Learn from industry experts and take your writing to the next level.', '2024-02-12 17:15:07'),
(41, 30, '\"Stand tall with Redwood Publications. Our books are like towering redwoods, rooted in storytelling traditions and reaching for the sky.', '2023-05-13 16:16:17'),
(42, 30, 'Get a sneak peek behind the scenes of our editorial process. See how our team transforms manuscripts into published works of art.', '2023-06-23 16:16:26'),
(43, 30, 'alling all bookworms! Dive into our summer reading list and discover the perfect book to accompany you on your adventures.', '2023-08-01 16:16:37');

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

--
-- A tábla adatainak kiíratása `postlike`
--

INSERT INTO `postlike` (`id`, `userId`, `postId`, `likeTime`) VALUES
(1, 1, 7, '2023-12-06 20:39:26'),
(2, 1, 13, '2024-04-06 19:39:26'),
(3, 1, 18, '2024-01-31 20:40:40'),
(4, 1, 19, '2024-02-17 20:40:40'),
(5, 1, 22, '2023-12-15 20:41:31'),
(6, 1, 23, '2024-01-11 20:41:31'),
(7, 1, 40, '2024-02-14 20:42:13'),
(8, 1, 36, '2023-10-24 19:42:42'),
(9, 1, 37, '2023-10-29 20:43:16'),
(10, 1, 38, '2023-11-13 20:43:16'),
(11, 1, 39, '2024-01-12 20:44:02'),
(12, 5, 13, '2024-04-06 19:44:19'),
(13, 5, 25, '2024-03-30 20:44:50'),
(14, 5, 26, '2024-04-12 19:44:50'),
(15, 5, 28, '2024-04-25 19:45:25'),
(16, 5, 32, '2023-07-29 19:45:55'),
(17, 5, 33, '2023-08-12 19:45:55'),
(18, 5, 41, '2023-05-14 19:46:39'),
(19, 5, 42, '2023-06-26 19:46:39'),
(20, 5, 43, '2023-08-04 19:47:26'),
(21, 5, 36, '2023-10-23 19:47:46'),
(22, 6, 11, '2024-01-10 20:48:24'),
(23, 6, 12, '2024-03-27 20:48:24'),
(24, 8, 20, '2024-02-17 20:49:19'),
(25, 8, 21, '2024-03-15 20:49:19'),
(26, 6, 29, '2023-05-01 19:49:58'),
(27, 6, 40, '2024-02-13 20:50:32'),
(28, 7, 18, '2024-01-31 20:51:02'),
(29, 7, 19, '2024-02-16 20:51:02'),
(30, 7, 20, '2024-02-15 20:51:37'),
(31, 7, 21, '2024-03-18 20:51:37'),
(32, 7, 25, '2024-03-29 20:52:14'),
(33, 7, 26, '2024-04-11 19:52:14'),
(34, 7, 30, '2023-07-09 19:52:56'),
(35, 7, 31, '2024-01-11 20:52:56'),
(36, 7, 41, '2023-05-15 19:53:44'),
(37, 7, 42, '2023-06-24 19:54:10'),
(38, 7, 43, '2023-08-03 19:54:10'),
(39, 7, 40, '2024-02-13 20:54:50'),
(40, 7, 34, '2023-09-22 19:55:11'),
(41, 7, 35, '2023-04-25 19:55:11'),
(42, 8, 13, '2024-04-06 19:56:13'),
(43, 8, 3, '2024-02-12 20:56:42'),
(44, 8, 4, '2024-02-13 20:56:42'),
(45, 8, 5, '2024-02-21 20:57:14'),
(46, 8, 28, '2024-04-23 19:57:36'),
(47, 8, 22, '2023-12-16 20:57:59'),
(48, 8, 23, '2024-01-11 20:57:59'),
(49, 8, 32, '2023-07-29 19:58:39'),
(50, 8, 33, '2023-08-08 19:58:39'),
(51, 8, 36, '2023-10-21 19:59:27'),
(52, 9, 25, '2024-03-29 20:59:56'),
(53, 9, 26, '2024-04-10 19:59:56'),
(54, 9, 28, '2024-04-23 20:00:30'),
(55, 9, 37, '2023-10-29 21:01:00'),
(56, 9, 38, '2023-11-13 21:01:00'),
(57, 9, 39, '2024-01-10 21:01:40'),
(58, 9, 36, '2023-10-23 20:01:58'),
(59, 9, 34, '2023-09-21 20:02:28'),
(60, 9, 35, '2023-04-24 20:02:28'),
(61, 9, 29, '2023-05-01 20:03:17'),
(62, 11, 7, '2023-10-22 20:03:44'),
(63, 11, 22, '2023-12-16 21:04:20'),
(64, 11, 23, '2024-01-11 21:04:20'),
(65, 11, 28, '2024-04-23 20:04:53'),
(66, 11, 8, '2023-10-09 20:05:19'),
(67, 11, 9, '2023-11-05 21:05:19'),
(68, 11, 10, '2023-11-20 21:06:00'),
(69, 11, 40, '2024-02-12 21:06:17'),
(70, 11, 30, '2023-07-05 20:06:45'),
(71, 11, 31, '2024-01-10 21:06:45'),
(72, 12, 11, '2024-01-08 21:07:35'),
(73, 12, 12, '2024-03-25 21:07:35'),
(74, 12, 20, '2024-02-15 21:08:17'),
(75, 12, 21, '2024-03-15 21:08:17'),
(76, 12, 18, '2024-01-31 21:09:05'),
(77, 12, 19, '2024-02-15 21:09:05'),
(78, 12, 7, '2023-10-22 20:09:43'),
(79, 12, 29, '2023-04-30 20:10:09'),
(80, 13, 20, '2024-02-16 21:10:43'),
(81, 13, 21, '2024-03-15 21:10:43'),
(82, 14, 3, '2024-02-10 21:11:12'),
(83, 14, 4, '2024-02-12 21:11:12'),
(84, 14, 5, '2024-02-20 21:11:48'),
(85, 14, 25, '2024-03-29 21:12:57'),
(86, 14, 26, '2024-04-10 20:12:57'),
(87, 14, 13, '2024-04-05 20:13:31'),
(88, 13, 3, '2024-02-10 21:14:00'),
(89, 13, 4, '2024-02-12 21:14:00'),
(90, 13, 5, '2024-02-20 21:14:35'),
(91, 13, 13, '2024-04-06 20:14:46'),
(92, 13, 28, '2024-04-23 20:15:14'),
(93, 13, 37, '2023-10-28 20:15:34'),
(94, 13, 38, '2023-11-13 21:15:34'),
(95, 13, 39, '2024-01-11 21:16:25'),
(96, 14, 32, '2023-07-28 20:17:26'),
(97, 14, 33, '2023-08-08 20:17:26'),
(98, 14, 40, '2024-02-12 21:18:11'),
(99, 15, 18, '2024-01-29 21:18:41'),
(100, 15, 19, '2024-02-15 21:18:41'),
(101, 15, 28, '2024-04-24 20:19:37'),
(102, 15, 20, '2024-02-15 21:20:01'),
(103, 15, 21, '2024-03-16 21:20:01'),
(104, 15, 36, '2023-10-21 20:20:39'),
(105, 15, 34, '2023-09-21 20:21:18'),
(106, 15, 35, '2023-04-25 20:21:18'),
(107, 15, 41, '2023-05-14 20:22:00'),
(108, 15, 42, '2023-06-23 20:22:00'),
(109, 15, 43, '2023-08-01 20:22:50'),
(110, 15, 37, '2023-10-28 20:23:10'),
(111, 15, 38, '2023-11-13 21:23:10'),
(112, 15, 39, '2024-01-10 21:23:52'),
(113, 17, 16, '2023-08-15 20:24:15'),
(114, 17, 17, '2023-10-10 20:24:15'),
(115, 17, 8, '2023-10-09 20:24:59'),
(116, 17, 9, '2023-11-05 21:24:59'),
(117, 17, 10, '2023-11-20 21:25:39'),
(118, 17, 11, '2024-01-08 21:25:53'),
(119, 17, 12, '2024-03-25 21:25:53'),
(120, 17, 7, '2023-10-22 20:26:26'),
(121, 17, 30, '2023-07-05 20:26:47'),
(122, 17, 31, '2024-01-10 21:26:47'),
(123, 17, 29, '2023-04-30 20:27:22'),
(124, 18, 28, '2024-04-23 20:27:54'),
(125, 18, 32, '2023-07-28 20:28:13'),
(126, 18, 33, '2023-08-09 20:28:13'),
(127, 18, 37, '2023-10-28 20:28:56'),
(128, 18, 38, '2023-11-13 21:28:56'),
(129, 18, 39, '2024-01-11 21:29:41'),
(130, 19, 40, '2024-02-13 21:29:53'),
(131, 19, 30, '2023-07-05 20:30:11'),
(132, 19, 31, '2024-01-10 21:30:11'),
(133, 19, 34, '2023-08-21 20:31:06'),
(134, 19, 35, '2023-04-23 20:31:06'),
(135, 21, 1, '2023-05-25 20:31:47'),
(136, 21, 2, '2023-08-11 20:31:47'),
(137, 21, 22, '2023-12-15 21:32:36'),
(138, 21, 23, '2024-01-10 21:32:36'),
(139, 21, 20, '2024-02-15 21:33:22'),
(140, 21, 21, '2024-03-15 21:33:22'),
(141, 22, 3, '2024-02-10 21:33:51'),
(142, 22, 4, '2024-02-12 21:33:51'),
(143, 22, 5, '2024-02-20 21:34:18'),
(144, 22, 7, '2023-10-23 20:34:29'),
(145, 22, 14, '2023-07-20 20:34:48'),
(146, 22, 15, '2023-09-11 20:34:48'),
(147, 23, 8, '2023-10-09 20:35:27'),
(148, 23, 9, '2023-11-05 21:35:27'),
(149, 23, 10, '2023-11-20 21:36:07'),
(150, 23, 11, '2024-01-10 21:36:24'),
(151, 23, 12, '2024-03-28 21:36:24'),
(152, 23, 22, '2023-12-15 21:36:51'),
(153, 23, 23, '2024-01-10 21:36:51'),
(154, 23, 28, '2024-04-23 20:37:38'),
(155, 24, 3, '2024-02-10 21:37:58'),
(156, 24, 4, '2024-02-12 21:37:58'),
(157, 24, 5, '2024-02-20 21:38:32'),
(158, 24, 11, '2024-01-08 21:38:40'),
(159, 24, 12, '2024-03-25 21:38:40'),
(160, 24, 22, '2023-12-15 21:39:14'),
(161, 24, 23, '2024-01-10 21:39:14'),
(162, 25, 22, '2024-01-15 21:39:43'),
(163, 25, 23, '2024-01-10 21:39:43'),
(164, 25, 25, '2024-03-29 21:40:22'),
(165, 25, 26, '2024-04-10 20:40:22'),
(166, 25, 28, '2024-04-23 20:40:46'),
(167, 25, 18, '2024-01-30 21:41:05'),
(168, 25, 19, '2024-02-15 21:41:05'),
(169, 26, 13, '2024-04-05 20:41:39'),
(170, 26, 18, '2024-01-29 21:42:00'),
(171, 26, 19, '2024-02-15 21:42:00'),
(172, 26, 24, '2023-07-11 20:42:30'),
(173, 27, 22, '2023-12-15 21:42:55'),
(174, 27, 23, '2024-01-11 21:42:55'),
(175, 27, 11, '2024-01-08 21:43:35'),
(176, 27, 12, '2024-03-25 21:43:35'),
(177, 27, 7, '2023-10-22 20:44:04'),
(178, 28, 18, '2024-01-29 21:44:26'),
(179, 28, 19, '2024-02-15 21:44:26'),
(180, 28, 25, '2024-03-29 21:45:06'),
(181, 28, 26, '2024-04-10 20:45:06'),
(182, 28, 28, '2024-04-23 20:45:32'),
(183, 29, 3, '2024-02-10 21:45:54'),
(184, 29, 4, '2024-02-12 21:45:54'),
(185, 29, 5, '2024-02-20 21:46:25'),
(186, 29, 1, '2023-05-25 20:46:35'),
(187, 29, 2, '2023-08-09 20:46:35'),
(188, 29, 7, '2023-10-22 20:47:03'),
(189, 29, 14, '2023-07-20 20:47:19'),
(190, 29, 15, '2023-09-11 20:47:19'),
(191, 29, 24, '2023-07-11 20:48:01'),
(192, 29, 25, '2024-03-29 21:48:18'),
(193, 29, 26, '2024-04-10 20:48:18'),
(194, 30, 18, '2024-01-29 21:48:48'),
(195, 30, 19, '2024-02-15 21:48:48'),
(196, 30, 1, '2023-05-25 20:49:25'),
(197, 30, 2, '2023-08-09 20:49:25'),
(198, 30, 22, '2023-12-15 21:49:55'),
(199, 30, 23, '2024-01-10 21:49:55'),
(200, 30, 24, '2023-07-10 20:50:28');

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `publisher`
--

CREATE TABLE `publisher` (
  `id` int(11) NOT NULL,
  `companyName` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- A tábla adatainak kiíratása `publisher`
--

INSERT INTO `publisher` (`id`, `companyName`) VALUES
(1, 'Bright Publications'),
(2, 'Stellar Press'),
(3, 'Horizon Books'),
(4, 'Evergreen Publishing'),
(5, 'Phoenix Press'),
(6, 'Cascade Books'),
(7, 'Silverleaf Publishers'),
(8, 'Summit Publishing'),
(9, 'Golden Pen Books'),
(10, 'Redwood Publications'),
(11, 'Cascade Books');

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

--
-- A tábla adatainak kiíratása `saved`
--

INSERT INTO `saved` (`id`, `userId`, `bookId`, `savedTime`) VALUES
(1, 7, 22, '2024-04-27 10:28:55'),
(2, 8, 15, '2024-03-12 11:28:55'),
(3, 22, 17, '2023-06-28 10:32:18'),
(4, 1, 25, '2024-04-10 10:34:25'),
(5, 29, 15, '2024-02-23 11:34:25'),
(6, 5, 4, '2024-03-06 11:35:09'),
(7, 18, 13, '2023-12-06 11:35:09'),
(8, 25, 3, '2024-04-17 10:36:05'),
(9, 11, 16, '2024-03-28 11:36:05'),
(10, 25, 10, '2024-03-13 11:36:37'),
(11, 19, 25, '2024-04-10 10:36:37'),
(12, 5, 15, '2024-03-01 11:38:29'),
(13, 3, 25, '2024-04-15 10:38:29'),
(14, 8, 9, '2024-03-30 11:39:06'),
(16, 24, 11, '2024-04-26 10:40:03'),
(17, 12, 7, '2024-04-24 10:40:03'),
(19, 25, 24, '2024-04-27 16:21:34'),
(21, 12, 2, '2024-04-27 18:58:46'),
(23, 12, 3, '2024-04-27 18:59:07');

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
-- A tábla adatainak kiíratása `user`
--

INSERT INTO `user` (`id`, `username`, `email`, `password`, `rank`, `firstName`, `lastName`, `phoneNumber`, `publicEmail`, `publicPhoneNumber`, `introDescription`, `website`, `image`, `registrationTime`, `firstLogin`, `deleted`, `coverColorId`, `userId`) VALUES
(1, 'emma_smith_writer', 'emma.smith@gmail.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'general', 'Emma', 'Smith', '06704631166', 1, 1, 'Hello, I\'m Emma Smith, a passionate writer eager to share my stories with the world.', 'www.emmasmithwriter.com', 'pictures/user/cica.jpg', '2023-04-12 11:22:45', 0, 0, 26, 1),
(2, 'b_taylor_', 'benjamin.taylor@gmail.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'general', 'Benjamin', 'Taylor', '06209472944', 1, 0, '', '', 'pictures/default-profile-pic-man.png', '2024-01-17 12:26:20', 1, 0, 3, 2),
(3, 'oliviajohnson1', 'olivia.johnson@gmail.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'general', 'Olivia', 'Johnson', '06707274276', 0, 0, '', '', 'pictures/default-profile-pic-man.png', '2022-01-14 12:28:31', 1, 0, 1, 3),
(4, 'ethan_martinez_books', 'ethan.martinez.books@gmail.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'general', 'Ethan ', 'Martinez', '06708493373', 0, 0, '', '', 'pictures/default-profile-pic-man.png', '2023-12-13 12:30:27', 1, 0, 1, 4),
(5, 'sophia_a_novels', 'sophiaanderson13@gmail.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'general', 'Sophia', 'Anderson', '06709475525', 0, 1, 'Greetings, fellow book lovers! I\'m Sophia Anderson, crafting stories that resonate with the soul:)', 'www.sophienovels.com', 'pictures/user/avatar-3.jpg', '2024-01-29 12:32:19', 0, 0, 27, 5),
(6, 'liam_brown_reads', 'liam.brown@gmail.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'general', 'Liam', 'Brown', '06708238213', 1, 1, 'Liam Brown here, diving into worlds both real and imagined, one page at a time.', 'www.liamthebrown.com', 'pictures/user/avatar-6.jpg', '2023-10-08 11:35:02', 0, 0, 28, 6),
(7, 'bella_wilson_stories', 'isabella.wilson@gmail.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'general', 'Isabella', 'Wilson', '0670947736', 1, 0, 'Welcome! Isabella Wilson here, painting pictures with words and crafting tales that linger in the mind.', NULL, 'pictures/user/avatar-2.jpg', '2023-10-04 11:36:07', 0, 0, 29, 7),
(8, 'maason_', 'masongarcia@gmail.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'general', 'Mason', 'Garcia', '06208342414', 1, 0, 'Mason Garcia at your service, creating stories that transport you to distant lands and ignite the imagination.', 'www.masongarcia.com', 'pictures/default-profile-pic-man.png', '2023-11-01 12:37:02', 0, 1, 30, 8),
(9, 'charlotte.lewis_', 'charlotte.lewis@gmail.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'general', 'Charlotte', 'Lewis', '06209637522', 0, 1, 'Hello, world! I\'m Charlotte Lewis, weaving words into tapestries of wonder and intrigue.', 'www.charlottelewis.com', 'pictures/default-profile-pic-man.png', '2024-02-20 12:37:57', 0, 1, 31, 9),
(10, 'alex_walker', 'alexanderwalker1313@gmail.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'general', 'Alexander', 'Walker', '06708365753', 0, 0, '', '', 'pictures/default-profile-pic-man.png', '2023-10-05 11:38:42', 0, 0, 1, 10),
(11, 'ameliaperez123', 'amelia.perez@gmail.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'general', 'Amelia', 'Perez', '06703278493', 1, 1, 'Greetings, fellow readers! I\'m Amelia Perez, spinning tales that whisk you away to realms of wonder.', 'www.ameliathereader.com', 'pictures/default-profile-pic-man.png', '2023-06-11 11:39:43', 0, 0, 32, 11),
(12, 'michael_king', 'michael.king@gmail.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'general', 'Micheal', 'King', '06208394242', 1, 1, 'Michael King here, crafting stories that illuminate the human experience and ignite the imagination.', 'www.michealking.com', 'pictures/user/avatar-7.jpg', '2023-08-18 11:40:50', 0, 0, 33, 12),
(13, 'harper.scott', 'harper.scott@gmail.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'general', 'Harper', 'Scott', '06201532953', 0, 1, 'Hello, readers! I\'m Harper Scott, conjuring worlds where every page is an adventure waiting to unfold.', NULL, 'pictures/default-profile-pic-man.png', '2023-12-28 12:41:51', 0, 0, 34, 13),
(14, 'evelyn_hall_books', 'evelynhall1432@gmail.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'general', 'Evelyn', 'Hall', '06708639477', 1, 0, 'Evelyn Hall here, weaving tales that evoke emotion and spark the imagination.', 'www.evelynhall.com0', 'pictures/user/avatar-1.jpg', '2024-01-03 12:43:04', 0, 0, 35, 14),
(15, 'daniel_131', 'danialadams@gmail.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'general', 'Daniel', 'Adams', '06201758473', 1, 0, 'Daniel Adams at your service, crafting stories that resonate long after the final page is turned.', 'www.danieladams.com', 'pictures/default-profile-pic-man.png', '2023-11-11 12:43:52', 0, 0, 36, 15),
(16, 'mia.campbell_', 'mia.campbell@gmail.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'general', 'Mia ', 'Campbell', '06709341833', 0, 0, '', '', 'pictures/default-profile-pic-man.png', '2023-07-15 11:44:53', 1, 0, 1, 16),
(17, 'lucas121', 'lucasnelson@gmail.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'general', 'Lucas', 'Nelson', '06206783562', 0, 1, 'Lucas Nelson here, penning tales that transport you to worlds both familiar and fantastical.', NULL, 'pictures/default-profile-pic-man.png', '2023-06-12 11:45:32', 0, 0, 37, 17),
(18, 'chloe_baker_author', 'chloe.baker@gmail.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'general', 'Chloe', 'Baker', '06708344627', 1, 1, 'Greetings, fellow bibliophiles! I\'m Chloe Baker, crafting stories that illuminate the human experience.', 'www.chloebaker.com', 'pictures/default-profile-pic-man.png', '2024-03-15 12:46:20', 0, 1, 26, 18),
(19, 'jackie_', 'jack.wright@gmail.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'general', 'Jack', 'Wright', '06709352342', 1, 0, 'Jack Wright here, embarking on literary journeys that stir the soul and captivate the mind.', 'www.jackwright.com', 'pictures/default-profile-pic-man.png', '2024-04-14 11:47:39', 0, 0, 38, 19),
(20, 'lily_hughes_', 'lily.hughes@gmail.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'general', 'Lily ', 'Hughes', '06708234142', 0, 0, '', '', 'pictures/default-profile-pic-man.png', '2024-04-24 11:48:48', 1, 0, 1, 20),
(21, 'bright_publications', 'info@brightpublications.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'publisher', 'John', 'Smith', '06204535324', 1, 1, 'Welcome to Bright Publications, where we illuminate minds with compelling stories and insightful narratives.\n', 'www.brightpublications.com', 'pictures/user/avatar-4.jpg', '2023-01-18 19:50:38', 0, 0, 39, 1),
(22, 'stellar_press', 'contact@stellarpress.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'publisher', 'Emily', 'Johnson', '06201742855', 1, 0, 'Stellar Press - Where every story shines. Join us on a journey through the cosmos of literature.', 'www.stellarpress.com', 'pictures/default-profile-pic-man.png', '2023-04-04 18:51:25', 0, 0, 40, 2),
(23, 'horizon_books', 'info@horizonbooks.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'publisher', 'Michael', 'Davis', '06701693855', 1, 1, 'Welcome to Horizon Books, where every page leads to new horizons of imagination and discovery.', 'www.horizonbooks.com', 'pictures/default-profile-pic-man.png', '2023-06-29 18:52:22', 0, 0, 26, 3),
(24, 'evergreen_publishing', 'contact@evergreenpublishing.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'publisher', 'Sarah', 'Brown', '06209743724', 1, 0, 'Evergreen Publishing - Cultivating timeless stories that endure through the ages.', 'www.evergreenpublishing.com', 'pictures/default-profile-pic-man.png', '2023-07-04 18:53:16', 0, 0, 41, 4),
(25, 'phoenix_press', 'info@phoenixpress.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'publisher', 'Daniel', 'Martinez', '06708494263', 1, 1, 'Rise from the ashes of ordinary reading. Join Phoenix Press for stories that ignite the imagination and inspire the soul.', 'www.phoenixpress.com', 'pictures/default-profile-pic-man.png', '2023-07-09 18:54:06', 0, 0, 42, 5),
(26, 'cascade_books', 'contact@cascadebooks.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'publisher', 'Olivia', 'Anderson', '06209858437', 1, 0, 'Embark on a journey of literary exploration with Cascade Books, where stories flow like a cascade of words.', 'www.cascadebooks.com', 'pictures/default-profile-pic-man.png', '2023-01-13 19:54:57', 0, 0, 43, 6),
(27, 'silverleaf_publishers', 'info@silverleafpublishers.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'publisher', 'Benjamin', 'Taylor', '06702749614', 1, 0, 'Silverleaf Publishers - Crafting stories as enduring as the silver leaves of literature.', 'www.silverleafpublishers.com', 'pictures/default-profile-pic-man.png', '2023-09-16 18:56:17', 0, 0, 44, 7),
(28, 'summit_publishing', 'contact@summitpublishing.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'publisher', 'Sophie', 'Clark', '06701387511', 1, 1, 'Reach new heights of literary excellence with Summit Publishing. Join us on the peak of storytelling.', 'www.summitpublishing.com', 'pictures/default-profile-pic-man.png', '2023-10-30 19:57:15', 0, 0, 45, 8),
(29, 'golden_pen_books', 'info@goldenpenbooks.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'publisher', 'Lucas', 'Nelson', '06201583261', 1, 0, 'At Golden Pen Books, every story is a stroke of brilliance. Join us in crafting tales that leave a lasting impression.', 'www.goldenpenbooks.com', 'pictures/user/avatar-5.jpg', '2024-02-01 19:58:01', 0, 0, 46, 9),
(30, 'redwood_publications', 'contact@redwoodpublications.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'publisher', 'Chloe', 'Baker', '06201529413', 1, 1, 'Stand tall with Redwood Publications, where stories grow strong and reach for the sky.', 'www.redwoodpublications.com', 'pictures/default-profile-pic-man.png', '2023-04-10 18:58:45', 0, 0, 1, 10),
(32, 'mayer.hedda', 'mayer.hedda@gmail.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'general', 'Mayer', 'Hedda', NULL, 0, 0, 'Hi! My name is Hedda.', NULL, 'pictures/default-profile-pic-man.png', '2024-04-27 16:48:23', 0, 0, 1, 21),
(33, 'mayer_adrienn', 'mayer.hedda2002@gmail.com', '754532304a272553d11bcc2b24d223ec7f51dfd9', 'general', 'Mayer', 'Adrienn', NULL, 0, 0, NULL, NULL, 'pictures/default-profile-pic-man.png', '2024-04-30 18:21:55', 0, 0, 1, 22);

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=53;

--
-- AUTO_INCREMENT a táblához `bookrating`
--
ALTER TABLE `bookrating`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=200;

--
-- AUTO_INCREMENT a táblához `bookshopping`
--
ALTER TABLE `bookshopping`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT a táblához `category`
--
ALTER TABLE `category`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;

--
-- AUTO_INCREMENT a táblához `categoryinterest`
--
ALTER TABLE `categoryinterest`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=194;

--
-- AUTO_INCREMENT a táblához `color`
--
ALTER TABLE `color`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=47;

--
-- AUTO_INCREMENT a táblához `follow`
--
ALTER TABLE `follow`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=130;

--
-- AUTO_INCREMENT a táblához `forgotpassword`
--
ALTER TABLE `forgotpassword`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `general`
--
ALTER TABLE `general`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=44;

--
-- AUTO_INCREMENT a táblához `postlike`
--
ALTER TABLE `postlike`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=201;

--
-- AUTO_INCREMENT a táblához `publisher`
--
ALTER TABLE `publisher`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT a táblához `saved`
--
ALTER TABLE `saved`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT a táblához `targetaudience`
--
ALTER TABLE `targetaudience`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT a táblához `user`
--
ALTER TABLE `user`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
