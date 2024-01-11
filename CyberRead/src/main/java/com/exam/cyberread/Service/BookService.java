package com.exam.cyberread.Service;

import com.exam.cyberread.Exception.BookException;
import com.exam.cyberread.Model.Book;
import com.exam.cyberread.Model.Category;
import com.exam.cyberread.Model.Language;
import com.exam.cyberread.Model.Targetaudience;
import org.json.JSONArray;
import org.json.JSONObject;


public class BookService {
    
    /**
     * @param userId: id of the logged in user
     * 
     * @return books
        * book id
        * cover image
        * title
        * author name
        * first name
        * last name
        * publisher company name
        * book description
        * pages number
        * book rating
        * saved
     * 
     * @throws BookException: Something wrong
     */
    public static JSONArray getMostSavedBooksOfTheMonth(Integer userId) throws BookException {
        try {
            return Book.getMostSavedBooksOfTheMonth(userId);
        } catch(Exception ex) {
            System.err.println(ex.getMessage());
            throw new BookException("Error in getMostSavedBooksOfTheMonth() method!");
        }
    }
    
    
    /**
     * @param userId: id of the logged in user
     * 
     * @return books
        * book id
        * cover image
        * title
        * author name
        * first name
        * last name
        * publisher company name
        * book description
        * pages number
        * book rating
        * saved
     * 
     * @throws BookException: Something wrong
     */
    public static JSONArray getPublishedBooks(Integer userId) throws BookException {
        try {
            return Book.getPublishedBooks(userId);
        } catch(Exception ex) {
            System.err.println(ex.getMessage());
            throw new BookException("Error is getPublishedBooks() method!");
        }
    }
    
    
    /**
     * @param userId: id of the logged in user
     * 
     * @return books
        * book id
        * cover image
        * title
        * author name
        * first name
        * last name
        * book description
        * pages number
        * book rating
        * saved
     * 
     * @throws BookException: Something wrong
     */
    public static JSONArray getSelfPublishedBooks(Integer userId) throws BookException {
        try {
            return Book.getSelfPublishedBooks(userId);
        } catch(Exception ex) {
            System.err.println(ex.getMessage());
            throw new BookException("Error is getSelfPublishedBooks() method!");
        }
    }
    
    
    /**
     * @param userId: id of the logged in user
     * 
     * @return books
        * book id
        * cover image
        * title
        * author name
        * first name
        * last name
        * publisher company name
        * book description
        * pages number
        * book rating
        * language
        * saved
     * 
     * @throws BookException: Something wrong
     */
    public static JSONArray getOneRandomBook(Integer userId) throws BookException {
        try {
            return Book.getOneRandomBook(userId);
        } catch(Exception ex) {
            System.err.println(ex.getMessage());
            throw new BookException("Error is getOneRandomBook() method!");
        }
    }
    
    
    /**
     * @param userId: id of the logged in user
     * 
     * @return books
        * book id
        * cover image
        * title
        * author name
        * first name
        * last name
        * publisher company name
        * book description
        * pages number
        * book rating
        * saved
     * 
     * @throws BookException: Something wrong
     */
    public static JSONArray getRecommandedBooks(Integer userId) throws BookException {
        try {
            return Book.getRecommandedBooks(userId);
        } catch(Exception ex) {
            System.err.println(ex.getMessage());
            throw new BookException("Error is getRecommandedBooks() method!");
        }
    }
    
    
    /**
     * @return
        * all target audiences
        * all categories
        * all languages
     * 
     * @throws BookException: Something wrong
     */
    public static JSONObject getDropDownValues() throws BookException {
        try {
            JSONObject values = new JSONObject();
            
            values.put("targetAudiences", Targetaudience.getAllTargetAudiences());
            values.put("categories", Category.getAllCategoryForPublication());
            values.put("languages", Language.getAllLanguages());
            
            return values;
        } catch(Exception ex) {
            System.err.println(ex.getMessage());
            throw new BookException("Error in getDropDownValues() method!");
        }
    }
    
    
    /**
     * @param userId
     * @param title
     * @param description
     * @param targetAudienceId
     * @param languageId
     * @param adultFiction
     * @param categoryId
     * @param statusId
     * @param price
     * @param coverImage
     * @param file
     * @param bankAccountNumber
     * @param chapterNumber
     * 
     * @return
        * errors: if something value is wrong
     * 
     * @throws BookException: Something wrong
     */
    public static JSONObject addBook(Integer userId, String title, String description, Integer targetAudienceId, Integer languageId, Boolean adultFiction, Integer categoryId, Integer statusId, Integer price, String coverImage, String file, String bankAccountNumber, Integer chapterNumber) throws BookException {
        try {
            JSONObject errors = BookService.bookDetailsCheck(title, description, targetAudienceId, languageId, adultFiction, categoryId, price, statusId, bankAccountNumber, coverImage, file);
            Integer freeChapterNumber = null;

            if(chapterNumber == null) {
                errors.put("chapterNumberError", "The chapter number field cannot be empty!");
            } else if(chapterNumber < 0) {
                errors.put("chapterNumberError", "The book cannot have less than zero chapters!");
            } else {
                freeChapterNumber = (int) Math.round(chapterNumber * 0.2);
            }
            
            
            if(errors.isEmpty()) {
                Integer result = Book.addBook(userId, title, description, targetAudienceId, languageId, adultFiction, categoryId, statusId, price, coverImage, file, bankAccountNumber, chapterNumber, freeChapterNumber);
                
                switch(result) {
                    case 2:
                        errors.put("targetAudeienceError", "This target audience does not exist!");
                        break;
                    case 3:
                        errors.put("languageError", "This language does not exist!");
                        break;
                    case 4:
                        errors.put("categoryError", "This category does not exist!");
                        break;
                    case 5:
                        errors.put("targetAudeienceError", "This target audience does not exist!");
                        errors.put("languageError", "This language does not exist!");
                        break;
                    case 6:
                        errors.put("targetAudeienceError", "This target audience does not exist!");
                        errors.put("categoryError", "This category does not exist!");
                        break;
                    case 7:
                        errors.put("languageError", "This language does not exist!");
                        errors.put("categoryError", "This category does not exist!");
                        break;
                    case 8:
                        errors.put("targetAudeienceError", "This target audience does not exist!");
                        errors.put("languageError", "This language does not exist!");
                        errors.put("categoryError", "This category does not exist!");
                        break;
                }
            }
            
            return errors;
        } catch(Exception ex) {
            System.err.println(ex.getMessage());
            throw new BookException("Error in addBook() methode!");
        }
    }
    
    
    /**
     * @param bookId
     * 
     * @return
        * book id
        * title
        * description
        * target audience id
        * language id
        * adult fiction
        * category id
        * status id
        * price
        * cover image
        * file
        * bank account number
     * 
     * @throws BookException: Something wrong
     */
    public static JSONObject getBookDetails(Integer bookId) throws BookException {
        try {
            return Book.getBookDetails(bookId);
        } catch(Exception ex) {
            System.err.println(ex.getMessage());
            throw new BookException("Error in getBookDetails() method!");
        }
    }
    
    
    /**
     * @param bookId
     * @param title
     * @param description
     * @param targetAudienceId
     * @param languageId
     * @param adultFiction
     * @param categoryId
     * @param statusId
        * 1: looking for a publisher
        * 2: self-published
     * @param price
     * @param coverImage
     * @param file
     * @param bankAccountNumber
     * @param chapterNumber
     * 
     * @return
        * errors: if something value is wrong
     *
     * @throws BookException: Something wrong
     */
    public static JSONObject setBook(Integer bookId, String title, String description, Integer targetAudienceId, Integer languageId, Boolean adultFiction, Integer categoryId, Integer statusId, Integer price, String coverImage, String file, String bankAccountNumber, Integer chapterNumber) throws BookException {
        try{
            JSONObject errors = BookService.bookDetailsCheck(title, description, targetAudienceId, languageId, adultFiction, categoryId, price, statusId, bankAccountNumber, coverImage, file);
            Integer freeChapterNumber = null;
            
            if(chapterNumber == null) {
                errors.put("chapterNumberError", "The chapter number field cannot be empty!");
            } else if(chapterNumber < 0) {
                errors.put("chapterNumberError", "The book cannot have less than zero chapters!");
            } else {
                freeChapterNumber = (int) Math.round(chapterNumber * 0.2);
            }
            
            
            if(errors.isEmpty()) {
                Integer result = Book.setBook(bookId, title, description, targetAudienceId, languageId, adultFiction, categoryId, statusId, price, coverImage, file, bankAccountNumber, chapterNumber, freeChapterNumber);
                        
                switch(result) {
                    case 2:
                        errors.put("targetAudeienceError", "This target audience does not exist!");
                        break;
                    case 3:
                        errors.put("languageError", "This language does not exist!");
                        break;
                    case 4:
                        errors.put("categoryError", "This category does not exist!");
                        break;
                    case 5:
                        errors.put("targetAudeienceError", "This target audience does not exist!");
                        errors.put("languageError", "This language does not exist!");
                        break;
                    case 6:
                        errors.put("targetAudeienceError", "This target audience does not exist!");
                        errors.put("categoryError", "This category does not exist!");
                        break;
                    case 7:
                        errors.put("languageError", "This language does not exist!");
                        errors.put("categoryError", "This category does not exist!");
                        break;
                    case 8:
                        errors.put("targetAudeienceError", "This target audience does not exist!");
                        errors.put("languageError", "This language does not exist!");
                        errors.put("categoryError", "This category does not exist!");
                        break;
                }
            }
            
            return errors;
        } catch(Exception ex) {
            System.err.println(ex.getMessage());
            throw new BookException("Error in setBook() method!");
        }
    }
    
    
    /**
     * @param title
     * @param description
     * @param targetAudienceId
     * @param languageId
     * @param adultFiction
     * @param categoryId
     * @param price
     * @param statusId
     * @param bankAccountNumber
     * @param coverImage
     * @param file
     * 
     * @return error
        * If empty then all data is correct
        * Else there is an error in the data
     * 
     * @throws com.exam.cyberread.Exception.BookException 
     */
    public static JSONObject bookDetailsCheck(String title, String description, Integer targetAudienceId, Integer languageId, Boolean adultFiction, Integer categoryId, Integer price, Integer statusId, String bankAccountNumber, String coverImage, String file) throws BookException {
        try {
            JSONObject errors = new JSONObject();

            if(title == null || title.isEmpty()) {
                errors.put("storyTitleError", "Title field cannot be empty!");
            } else if(title.length() < 3) {
                errors.put("storyTitleError", "Title must be 3 caracter long!");
            } else if(title.length() > 50) {
                errors.put("storyTitleError", "The title cannot be longer than 50 characters!");
            }

            if(description == null || description.isEmpty()) {
                errors.put("descriptionError", "The description field cannot be empty!");
            } else if(description.length() < 20) {
                errors.put("descriptionError", "The description must be 20 caracter long.");
            } else if(description.length() > 1000) {
                errors.put("descriptionError", "The description cannot be longer than 1000 characters!");
            }

            if(targetAudienceId == null) {
                errors.put("targetAudienceError", "The target audience field cannot be empty!");
            }

            if(languageId == null) {
                errors.put("languageError", "The language field cannot be empty!");
            }

            if(adultFiction == null) {
                adultFiction = false;
            }

            if(categoryId == null) {
                errors.put("categoryError", "The category field cannot be empty!");
            }

            if(price != null) {
                if(price < 1000) {
                    errors.put("priceError", "The price must be a minimum of 1000 Hungarian Forints!");
                } else {
                    price = (int) (price / 0.80);
                }
            }

            if(statusId == null) {
                errors.put("statusError", "You have to choose one option!");
            } else if(statusId < 1 || statusId > 2) {
                errors.put("statusError", "The option does not exist!");
            } else {
                if(statusId == 2 && price == null) {
                    errors.put("priceError", "The price field cannot be empty!");
                } else if(statusId == 1) {
                    price = 0;
                }

                if(statusId == 2 && (bankAccountNumber == null || bankAccountNumber.isEmpty())) {
                    errors.put("bankAccountNumberError", "The bank account number field cannot be empty!");
                } else if(statusId == 1) {
                    bankAccountNumber = "";
                }
            }

            if(coverImage == null || coverImage.isEmpty()) {
                errors.put("coverImageError", "The cover image cannot be empty!");
            }

            if(file == null || file.isEmpty()) {
                errors.put("bookFileError", "The book file cannot be empty!");
            }

            return errors;
        } catch(Exception ex) {
            System.err.println(ex.getMessage());
            throw new BookException("Error in bookDetailsCheck() method!");
        }
    }
    
    
    /**
     * @param userId
     * 
     * @return
        * book id
        * cover image
        * title
        * author name
        * first name
        * last name
        * book description
        * pages number
        * book rating
        * language
        * saved
     * 
     * @throws BookException: Something wrong
     */
    public static JSONArray getOneRandomLookingForPublisherBook(Integer userId) throws BookException {
        try {
            return Book.getOneRandomLookingForPublisherBook(userId);
        } catch(Exception ex) {
            System.err.println(ex.getMessage());
            throw new BookException("Error in getOneRandomLookingForPublisherBook() method!");
        }
    }
    
    
    /**
     * @param userId
     * 
     * @return
        * book id
        * cover image
        * title
        * author name
        * first name
        * last name
        * book description
        * pages number
        * book rating
        * language
        * saved
     * 
     * @throws BookException 
     */
    public static JSONArray getRecommandedBooksForPublisher(Integer userId) throws BookException {
        try {
            return Book.getRecommandedBooksForPublisher(userId);
        } catch(Exception ex) {
            System.err.println(ex.getMessage());
            throw new BookException("Error in getRecommandedBooksForPublisher() method!");
        }
    }
    
    
    /**
     * @param userId
     * 
     * @return
        * book id
        * cover image
        * title
        * author name
        * first name
        * last name
        * book description
        * pages number
        * book rating
        * language
        * saved
     * 
     * @throws BookException: Something wrong
     */
    public static JSONObject getRandomBookByCategory(Integer userId) throws BookException {
        try {
            JSONArray books = Book.getRandomBookByCategory(userId);

            JSONObject result = new JSONObject();

            for (int i = 0; i < books.length(); i++) {
                JSONObject bookData = books.getJSONObject(i);
                String categoryName = bookData.getString("categoryName");
                bookData.remove("categoryName");

                if (!result.has(categoryName)) {
                    JSONArray categoryBooks = new JSONArray();
                    categoryBooks.put(bookData);
                    result.put(categoryName, categoryBooks);
                } else {
                    JSONArray categoryBooks = result.getJSONArray(categoryName);
                    categoryBooks.put(bookData);
                    result.put(categoryName, categoryBooks);
                }
            }
            return result;
        } catch (Exception ex) {
            System.err.println(ex.getMessage());
            throw new BookException("Error in getRandomBookByCategory() method!");
        }
    }
    
    
    /**
     * @param userId: logged in user id
     * @param profileUsername: username associated with the opened profile
     * 
     * @return
        * books:
            * book id
            * category name
            * cover image
            * title
            * author name
            * first name
            * last name
            * company name
            * book description
            * pages number
            * book rating
            * language
            * saved
        * own books
     * 
     * @throws BookException: Something wrong
     */
    public static JSONObject getUserBooks(Integer userId, String profileUsername) throws BookException {
        try {
            return Book.getUserBooks(userId, profileUsername);
        } catch(Exception ex) {
            System.err.println(ex.getMessage());
            throw new BookException("Error in getUserBooks() method!");
        }
    }
    
    
    /**
     * @param userId
     * @param bookId
     * 
     * @return
        * saveBookError
     * 
     * @throws BookException: Something wrong
     */
    public static JSONObject saveBook(Integer userId, Integer bookId) throws BookException {
        try {
            return Book.saveBook(userId, bookId);
        } catch(Exception ex) {
            System.err.println(ex.getMessage());
            throw new BookException("Error in saveBook() method!");
        }
    }
    
    
    /**
     * @param userId
     * @param bookId
     * 
     * @return
        * deleteSavedBookError
     * 
     * @throws BookException: Something wrong
     */
    public static JSONObject deleteSavedBook(Integer userId, Integer bookId) throws BookException {
        try {
            return Book.deleteSavedBook(userId, bookId);
        } catch(Exception ex) {
            System.err.println(ex.getMessage());
            throw new BookException("Error in deleteSavedBook() method!");
        }
    }
    
    
    /**
     * @param userId
     * @param bookId
     * 
     * @return
        * deleteBookError
     * 
     * @throws BookException: Something wrong
     */
    public static JSONObject deleteBook(Integer userId, Integer bookId) throws BookException {
        try {
            return Book.deleteBook(userId, bookId);
        } catch(Exception ex) {
            System.err.println(ex.getMessage());
            throw new BookException("Error in deleteBook() method!");
        }
    }
    
}
