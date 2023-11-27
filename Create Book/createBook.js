

//* DRAG AND DROP IMAGE TO COVER PHOTO + UPLOAD FILE
const dropAreaPicture = document.getElementById('dropAreaPicture');
const inputPicture = document.getElementById('inputPicture');
const imgView = document.getElementById('imgView');

const dropAreaFile = document.getElementById('dropAreaFile');
const inputFile = document.getElementById('inputFile');
const fileView = document.getElementById('fileView');

var filePass = false;
var picPass = false;
//? IMAGE
inputPicture.addEventListener("change", uploadImage);

var height, width;


function uploadImage() {
    let imgLink = URL.createObjectURL(inputPicture.files[0]);
    imgView.style.backgroundImage = `url(${imgLink})`;
    imgView.textContent = "";
    imgView.style.border = 0;

    var img = new Image();
    img.src = imgLink;

    img.onload = function(){
        height = img.naturalHeight;
        width = img.naturalWidth;
        console.log("A kép szélessége: " + width);
        console.log("A kép magassága: " + height);
    }

    

    if (imgLink == "") {
        picPass = false;
        console.log("pic pass value:" + picPass);

    } else {
        picPass = true;
        console.log("pic pass value:" + picPass);

    }
}

dropAreaPicture.addEventListener('dragover', (e) => {
    e.preventDefault();
})

dropAreaPicture.addEventListener('drop', (e) => {
    e.preventDefault();
    inputPicture.files = e.dataTransfer.files;
    uploadImage();
    console.log(inputPicture.value);
})

//? FILE
inputFile.addEventListener("change", (e) => {
    e.preventDefault();
    console.log("lefut a change");
    uploadFile();
});

function uploadFile() {
    // let fileLink = URL.createObjectURL(inputFile.files[0]);
    console.log(inputFile.value);
    imgView.textContent = "";

    var fileName = inputFile.value.split('\\').pop();
    console.log("perjel után: " + fileName);
    //todo: MEGCSINÁLNI, HOGY CSAK A filename.pdf-ET ÍRJA KI 
    fileView.innerHTML = `
        <img class="addPhoto" src="../icons/createBook/upload-file.png" id="addFile">
        <p class="uploadP">You uploaded this:<br> ${inputFile.value}</p>
    `;
    // console.log("Lefutott az uploadfile");
    if (inputFile.value == "") {
        filePass = false;
        console.log("pic pass value:" + filePass);
    } else {
        filePass = true;
        console.log("pic pass value:" + filePass);
    }
}

function contact() {
    var file = document.getElementById("file");
    file.onchange = function () {
        if (!file.value == "") {
            var filesize = (file.files[0].size / 1024) + 1;
            var extra = " KiB";
            if (filesize >= 1024) {
                filesize = filesize / 1024;
                extra = " MiB";
            }
            var span = document.getElementById("filename");
            filesize = Math.round(filesize);
            span.innerHTML = file.value.split("\").pop() + "(" + filesize + extra +"));
        }
    }
}

dropAreaFile.addEventListener('dragover', (e) => {
    e.preventDefault();
})

dropAreaFile.addEventListener('drop', (e) => {
    e.preventDefault();
    inputFile.files = e.dataTransfer.files;
    uploadFile();
    console.log(inputFile.value);
    console.log("lefut a drop a fájlnál");
})



//* PROCESSING OTHER INPUTS
const title = document.getElementById('inputStoryTitle');
const description = document.getElementById('inputDescription');
const selectAudience = document.getElementById("selectTargetAudience");
const selectLanguage = document.getElementById('selectLanguage');
const selectCategory = document.getElementById('selectCategory');
const bankAccNumber = document.getElementById('inputBankNum');
const bookPrice = document.getElementById('inputBookPrice');

const charCounterTitle = document.getElementById('characterCounterTitle');
const charCounterDes = document.getElementById('characterCounterDes');

const nextBtn = document.getElementById('Next');


//* ERROR FIELDS
const titleError = document.getElementById('titleErr');
const descriptionError = document.getElementById('descriptErr');
const audienceError = document.getElementById('audienceErr');
const languageError = document.getElementById('languageErr');
const categoryError = document.getElementById('categoryErr');
const bankError = document.getElementById('BankNumError');
const priceError = document.getElementById('PriceError');

//* VARIABLES FOR ACTIVATE BUTTON
var titlePass = false;
var descriptionPass = false;
var audiencePass = false;
var languagePass = false;
var categoryPass = false;
var publishingPass = false;   //! nincs használva
var bankPass = false; //! csak akkor kell ha selpublish
var pricePass = false; //! csak akkor kell ha selpublish

// function Events() {
const storyname = document.getElementById('StoryName');
//? TITLE 
function MinTitle(titleValue) {
    if (titleValue.length < 3) {
        title.classList.add('inputError');
        console.log("Title error: too short - " + titleValue);
        return false;
    }
    return true;
}

title.addEventListener('input', (e) => {
    e.preventDefault();
    const currentText = title.value;
    let count = currentText.length;
    charCounterTitle.textContent = `${count}/50`;

    if (count >= 45) {
        // console.log("bemegy az ifbe");
        charCounterTitle.classList.remove('counter');
        charCounterTitle.classList.add('counterErrorLight');

        if (count == 50) {
            charCounterTitle.classList.remove('counterErrorLight');
            charCounterTitle.classList.add('counterErrorBold');
        } else {
            charCounterTitle.classList.remove('counterErrorBold');
            charCounterTitle.classList.add('counterErrorLight');
        }
    } else {
        charCounterTitle.classList.value = '';
        charCounterTitle.classList.add('small', 'counter');
    }
})

title.addEventListener('focusout', (e) => {
    e.preventDefault();
    const titleValue = title.value;
    if (titleValue == "") {
        title.classList.add('inputError');
        titleError.innerText = "Title cannot be empty";
        titlePass = false;
        console.log("TitlePass value: " + titlePass);
    } else {
        const functionValue = MinTitle(titleValue);
        if (functionValue == false) {
            titlePass = false;
            titleError.innerText = "Title must be 3 caracter long.";
            title.classList.add('inputError');
            console.log("A title függvény értéke: " + functionValue);
            console.log("TitlePass value: " + titlePass);
        } else {
            title.classList.add('inputPass');
            titlePass = true;
            console.log("TitlePass value: " + titlePass);
            storyname.textContent = title.value;
        }
    }

})

title.addEventListener('focusin', (e) => {
    e.preventDefault();
    title.classList.remove('inputError');
    title.classList.remove('inputPass');
    titleError.innerText = "";
    storyname.textContent = "Untitled Story";
})
// #############################################
//? DESCRIPTION
function MinDesc(descriptionValue) {
    if (descriptionValue.length < 20) {
        description.classList.add('inputError');
        console.log("Description error: too short - " + descriptionValue);
        return false;
    }
    return true;
}

description.addEventListener('input', (e) => {
    e.preventDefault();
    const currentText = description.value;
    const count = currentText.length;
    charCounterDes.textContent = `${count}/1000`;

    if (count >= 950) {
        console.log("bemegy az ifbe");
        charCounterDes.classList.remove('counter');
        charCounterDes.classList.add('counterErrorLight');

        if (count == 1000) {
            charCounterDes.classList.remove('counterErrorLight');
            charCounterDes.classList.add('counterErrorBold');
        } else {
            charCounterDes.classList.remove('counterErrorBold');
            charCounterDes.classList.add('counterErrorLight');
        }
    } else {
        charCounterDes.classList.value = '';
        charCounterDes.classList.add('small', 'counter');
    }
})

description.addEventListener('focusout', (e) => {
    e.preventDefault();
    const descValue = description.value;
    if (descValue == "") {
        description.classList.add('inputError');
        descriptionError.innerText = "The description field cannot be empty";
        descriptionPass = false;
        console.log("descriptionPass value: " + descriptionPass);
    } else {
        const functionValue = MinDesc(descValue);
        if (functionValue == false) {
            descriptionPass = false;
            descriptionError.innerText = "The description must be 20 caracter long.";
            description.classList.add('inputError');
            console.log("A descript. függvény értéke: " + functionValue);
            console.log("descriptionPass value: " + descriptionPass);
        } else {
            description.classList.add('inputPass');
            descriptionPass = true;
            console.log("descriptionPass value: " + descriptionPass);
        }
    }
})

description.addEventListener('focusin', (e) => {
    e.preventDefault();
    description.classList.remove('inputError');
    description.classList.remove('inputPass');
    descriptionError.innerText = "";
})

// #############################################
function disableDefaultOption(select) {
    const defaultOption = select.querySelector('option[value="0"]');
    if (defaultOption) {
        defaultOption.disabled = true;
    }
}

function VerifyDropdown(select, errorField, selection) {

    if (select.value == 0) {
        const errorMessage = `The ${selection} cannot be the default value.`;
        errorField.innerHTML = `<p>${errorMessage}</p>`;
        console.log(selection + ": wrong choice");
        select.classList.add('inputError');
        return false;
    }
    return true;
}

//? AUDIENCE DROPDOWN
var audienceData;
selectAudience.addEventListener('focusout', (e) => {
    e.preventDefault();
    const audienceValue = e.target.value;
    console.log("You selected: " + audienceValue);

    const functionValue = VerifyDropdown(selectAudience, audienceError, "Audience");
    if (functionValue == true) {
        selectAudience.classList.add('inputPass');
        audiencePass = true;
        console.log("audiencePass value: " + audiencePass);
        audienceData = audienceValue;
        console.log(audienceData);
    }
})

selectAudience.addEventListener('change', function () {
    // Az alapértelmezett érték letiltása, ha már választottak
    if (this.value !== "0") {
        disableDefaultOption(this);
    }
});

selectAudience.addEventListener('focusin', (e) => {
    e.preventDefault();
    selectAudience.classList.remove('inputError');
    selectAudience.classList.remove('inputPass');
    audienceError.innerHTML = "";
})
// #############################################
//? LANGUAGE DROPDOWN
var languageData;
selectLanguage.addEventListener('focusin', (e) => {
    e.preventDefault();
    selectLanguage.classList.remove('inputError');
    selectLanguage.classList.remove('inputPass');
    languageError.innerHTML = "";
})

selectLanguage.addEventListener('focusout', (e) => {
    e.preventDefault();
    const languageValue = e.target.value;
    console.log("You selected: " + languageValue);

    const functionValue = VerifyDropdown(selectLanguage, languageError, "Langugage");
    if (functionValue == true) {
        selectLanguage.classList.add('inputPass');
        languagePass = true;
        console.log("audiencePass value: " + languagePass);
        languageData = languageValue;
        console.log(languageData);
    }
})

selectLanguage.addEventListener('change', function () {
    // Az alapértelmezett érték letiltása, ha már választottak
    if (this.value !== "0") {
        disableDefaultOption(this);
    }
});

// #############################################
//? CATEGORY DROPDOWN
var categoryData;
selectCategory.addEventListener('focusin', (e) => {
    e.preventDefault();
    selectCategory.classList.remove('inputError');
    selectCategory.classList.remove('inputPass');
    categoryError.innerHTML = "";
})

selectCategory.addEventListener('focusout', (e) => {
    e.preventDefault();
    const categoryValue = e.target.value;
    console.log("You selected: " + categoryValue);

    const functionValue = VerifyDropdown(selectCategory, categoryError, "Category");
    if (functionValue == true) {
        selectCategory.classList.add('inputPass');
        categoryPass = true;
        console.log("audiencePass value: " + categoryPass);
        categoryData = categoryValue;
        console.log(categoryData);
    }
})

selectCategory.addEventListener('change', function () {
    // Az alapértelmezett érték letiltása, ha már választottak
    if (this.value !== "0") {
        disableDefaultOption(this);
    }
});


//? Radio Buttons
const checkboxes = document.querySelectorAll('.checkinput');
const bankAccDiv = document.getElementById('bankAcc-div');
const priceDiv = document.getElementById('bookPrice-outsideDiv');
var publishingForm;
var pubCheck = false;
var selfCheck = false;
checkboxes.forEach(function (radioButton) {
    radioButton.addEventListener('change', function () {
        // Ellenőrizze, hogy melyik rádiógomb van bejelölve
        if (this.checked) {
            publishingForm = this.id;
            // console.log("Bejelölt rádiógomb: " + publishingForm);
            if (publishingForm == "SelfPublish") {
                console.log("Aktívak a mezők");
                bankAccDiv.hidden = false;
                priceDiv.hidden = false;

                selfCheck = true;
                pubCheck = false;
                console.warn('Selfcheck value: ', selfCheck);
                console.warn('Pubcheck value: ', pubCheck);
            }

            if (publishingForm == "PublisherPublish") {
                console.log("Mezők deaktiválása");
                bankAccDiv.hidden = true;
                priceDiv.hidden = true;

                pubCheck = true;
                selfCheck = false;
                console.warn('Selfcheck value: ', selfCheck);
                console.warn('Pubcheck value: ', pubCheck);

            }
        }
    });
});

function validateChecks(errorField, pubCheck, selfCheck){
    /**
     * input parameters
     * @param {errorField} - Div
     * @param {pubCheck} - Boolean
     * @param {selfCheck} - Boolean
     * 
    */

    if (pubCheck == false && selfCheck == false) {
        errorField.innerHTML = `<p>You have to choose one option.</p>`;
    }

    if (pubCheck != false || selfCheck != false) {
        errorField.innerHTML = '';

    }
}


//? BANK ACC NUMBER


//? MIN PRICE
function minPrice(priceValue){
    if (priceValue < 1000) {
        bookPrice.classList.add('inputError');
        console.log("price error: too low");
        return false;
    }
    return true;
}

bookPrice.addEventListener('focusout', (e)=>{
    e.preventDefault();
    const priceValue = bookPrice.value;
    if (priceValue == "") {
        bookPrice.classList.add('inputError');
        priceError.innerText = "The price field cannot be empty";
        pricePass = false;
        console.log("pricePass value: " + pricePass);
    } else {
        const minFunctionValue = minPrice(priceValue);
        if (minFunctionValue == false) {
            pricePass = false;
            priceError.innerText = "The price must be a minimum of 1000 Hungarian Forints!";
            bookPrice.classList.add('inputError');
            console.log("A minPrice függvény értéke: " + minFunctionValue);
            console.log("pricePass value: " + pricePass);
        } else {
            bookPrice.classList.add('inputPass');
            pricePass = true;
            console.log("pricePass value: " + descriptionPass);
        }
    }
})

bookPrice.addEventListener('focusin', (e) => {
    e.preventDefault();
    bookPrice.classList.remove('inputError');
    bookPrice.classList.remove('inputPass');
    priceError.innerText = "";
})
// #############################################
//? NEXT BUTTON

// function ActivateNext(nextBtn) {
//     if (filePass == true &&
//         picPass == true &&
//         titlePass == true &&
//         descriptionPass == true &&
//         audiencePass == true &&
//         languagePass == true &&
//         categoryPass == true) {
//         console.log("Bumm aktív a gomb");
//         nextBtn.disabled = false;
//     }
// }



