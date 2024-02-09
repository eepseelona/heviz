

// change the like icon when hovering over or clicked on the like
// minden poszt kártyát itt hozunk létre, nem pedig html-ben
const dataUrl = './db.json';
const pcGroup = document.getElementById("kulsoPostCard");

// CONTROL MODAL INPUT
const modal_textarea = document.getElementById('message-text');
const characterCounterText = document.getElementById('characterCounter');
const charCounterDes = document.getElementById('characterCounter');

modal_textarea.addEventListener('input', (e) => {
    e.preventDefault();
    const currentText = modal_textarea.value;
    let count = currentText.length;
    characterCounterText.textContent = `${count}/1000`;

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
});

fetch(dataUrl)
    .then(response => {
        if (!response.ok) {
            throw new Error('Hiba a fájl betöltése közben');
        }
        return response.json();
    })

    .then(data => {
        const posts = data.posts;       //* ezzel hivatkozik a json azon tömbjében amiben az adatok vannak
        for (const posts of data.posts) {
            // console.log(`Felhasználónév: ${posts.username}`);
            // console.log('felhaszn');
            console.log(`${posts.id}`);
            console.log(`${posts.username}`);

            pcGroup.innerHTML += `
                <div class="post-card ">
                    <div class="first-row">
                        <!--? profil kép helye  -->
                        <div class="post-profile-icon rounded-circle shadow-sm" style="background-image: url('${posts.profilPicURL}');"></div>
                        <!--? User nevének helye -->
                        <div class="userName">
                            <p class="card-user-name">${posts.username}</p>
                        </div>
                        <div class="cardDate align-content-end">
                            <p class="card-date-text">${posts.postTime}</p>
                        </div>
                    </div>

                    <div class="postText">
                        <p class="post-text">${posts.text}</p>
                    </div>

                    <div class="last-row">
                        
                        <div class="like-and-share">
                            <div class="d-flex flex-column align-items-center emptyLike">
                              
                                <button class="like-button border-0 bg-transparent" id="like"><img src="../icons/GenFeed/heart.png" alt="not like"></button>
                             
                            </div>
                            <div class="d-flex flex-column align-items-center">
                                <div class="share"><svg xmlns="http://www.w3.org/2000/svg" width="23" height="23" fill="currentColor" class="bi bi-share-fill" viewBox="0 0 16 16">
                                    <path d="M11 2.5a2.5 2.5 0 1 1 .603 1.628l-6.718 3.12a2.499 2.499 0 0 1 0 1.504l6.718 3.12a2.5 2.5 0 1 1-.488.876l-6.718-3.12a2.5 2.5 0 1 1 0-3.256l6.718-3.12A2.5 2.5 0 0 1 11 2.5"/>
                                    </svg>
                                </div>
                                
                            </div>
                        </div>
                    </div>
                </div>
            `;
        }
    }
    )


let likeButtons = document.querySelectorAll(".like-button");
var liked = false;

likeButtons.forEach(likeButton => {
    likeButton.addEventListener("click", () => {
        let imgElement = likeButton.querySelector("img");

        if (!liked) {
            imgElement.src = "../icons/GenFeed/filled_heart.png";
            liked = true;
        } else {
            imgElement.src = "../icons/GenFeed/heart.png";
            liked = false;
        }
    });
});

