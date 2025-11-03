// Конфигурация API
const API_CONFIG = {
    baseUrl: 'http://localhost:8000',
    endpoints: {
        decks: '/decks',
        cards: '/cards'
    }
};

// Глобальные переменные
let currentDeckId = null;
let decks = [];
let cards = [];
let reviewCards = [];
let currentReviewIndex = 0;
let isCardFlipped = false;

// Инициализация при загрузке страницы
document.addEventListener('DOMContentLoaded', function () {
    initializeTheme();
    setupEventListeners();
    loadDecks();
});


// Настройка обработчиков событий
function setupEventListeners() {
    // Кнопки создания
    document.getElementById('createDeckBtn').addEventListener('click', createDeck);
    document.getElementById('createCardBtn').addEventListener('click', createCard);
    document.getElementById('startReviewBtn').addEventListener('click', startReview);
    document.getElementById('exitReviewBtn').addEventListener('click', exitReview);

    // Обработчики для карточки повторения
    document.getElementById('reviewCard').addEventListener('click', flipCard);
    
    // Обработчики для кнопок оценки
    document.querySelectorAll('.review-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            const quality = parseInt(this.getAttribute('data-quality'));
            rateCard(quality);
        });
    });

    // Быстрые клавиши
    document.addEventListener('keydown', handleKeyboardShortcuts);
}


// ==================== РАБОТА С КОЛОДАМИ ====================

// Создание новой колоды
async function createDeck() {
    const name = document.getElementById('deckName').value.trim();
    const description = document.getElementById('deckDescription').value.trim();

    if (!name) {
        showNotification('Введите название колоды!', 'error');
        return;
    }

    try {
        const deck = await apiCreateDeck(name, description);
        decks.push(deck);
        updateDecksList();
        
        // Очистка формы
        document.getElementById('deckName').value = '';
        document.getElementById('deckDescription').value = '';
        
        showNotification('Колода' + {name} +  'создана!');
    } catch (error) {
        showNotification('Ошибка создания колоды: ' + error.message, 'error');
    }
}

// Загрузка всех колод
async function loadDecks() {
    try {
        const response = await fetch(API_CONFIG.baseUrl + API_CONFIG.endpoints.decks);
        if (response.ok) {
            decks = await response.json();
            updateDecksList();
        } else {
            throw new Error('Ошибка загрузки колод');
        }
    } catch (error) {
        showNotification('Ошибка загрузки колод: ' + error.message, 'error');
    }
}

// Обновление списка колод в интерфейсе
function updateDecksList() {
    const decksList = document.getElementById('decksList');
    decksList.innerHTML = '';
    
    if (decks.length === 0) {
        decksList.innerHTML = `
            <div class="deck-item">
                <div class="deck-name">Нет колод</div>
                <div class="deck-description">Создайте первую колоду для начала работы</div>
            </div>
        `;
        return;
    }

    decks.forEach(deck => {
        const deckItem = document.createElement('div');
        deckItem.className = 'deck-item';
        deckItem.innerHTML = `
            <div class="deck-header">
                <div class="deck-name">${escapeHtml(deck.name)}</div>
                <div class="deck-actions">
                    <button class="action-btn btn-primary" onclick="selectDeck('${deck.id}')">Открыть</button>
                    <button class="action-btn btn-danger" onclick="deleteDeck('${deck.id}')">Удалить</button>
                </div>
            </div>
            <div class="deck-description">${escapeHtml(deck.description ,'Нет описания')}</div>
            <div class="deck-stats">
                <span>📅 ${new Date(deck.createdAt).toLocaleDateString()}</span>
                <span>🎴 ${getDeckCardCount(deck.id)} карточек</span>
            </div>
        `;
        decksList.appendChild(deckItem);
    });
}

// Выбор колоды для работы
async function selectDeck(deckId) {
    currentDeckId = deckId;
    const deck = decks.find(d => d.id === deckId);
    
    if (deck) {
        document.getElementById('selectedDeckName').textContent = deck.name;
        document.getElementById('noDeckSelected').classList.add('hidden');
        document.getElementById('deckSelected').classList.remove('hidden');
        await loadCards(deckId);
    }
}

// Удаление колоды
async function deleteDeck(deckId) {
    if (!confirm('Удалить эту колоду и все карточки в ней?')) return;

    try {
        await apiDeleteDeck(deckId);
        decks = decks.filter(d => d.id !== deckId);
        updateDecksList();
        
        if (currentDeckId === deckId) {
            currentDeckId = null;
            document.getElementById('noDeckSelected').classList.remove('hidden');
            document.getElementById('deckSelected').classList.add('hidden');
        }
        
        showNotification('Колода удалена', 'success');
    } catch (error) {
        showNotification('Ошибка удаления: ' + error.message, 'error');
    }
}

// ==================== РАБОТА С КАРТОЧКАМИ ====================

// Создание новой карточки
async function createCard() {
    const question = document.getElementById('cardQuestion').value.trim();
    const answer = document.getElementById('cardAnswer').value.trim();

    if (!question || !answer) {
        showNotification('Заполните вопрос и ответ!', 'error');
        return;
    }

    if (!currentDeckId) {
        showNotification('Сначала выберите колоду!', 'error');
        return;
    }

    try {
        const card = await apiCreateCard(currentDeckId, question, answer);
        cards.push(card);
        updateCardsList();
        
        // Очистка формы
        document.getElementById('cardQuestion').value = '';
        document.getElementById('cardAnswer').value = '';
        
        showNotification('Карточка добавлена!', 'success');
    } catch (error) {
        showNotification('Ошибка создания карточки: ' + error.message, 'error');
    }
}

// Загрузка карточек колоды
async function loadCards(deckId) {
    try {
        const response = await fetch(`${API_CONFIG.baseUrl}${API_CONFIG.endpoints.decks}/${deckId}/cards`);
        if (response.ok) {
            cards = await response.json();
            updateCardsList();
        } else {
            throw new Error('Ошибка загрузки карточек');
        }
    } catch (error) {
        showNotification('Ошибка загрузки карточек: ' + error.message, 'error');
    }
}

// Обновление списка карточек в интерфейсе
function updateCardsList() {
    const cardsList = document.getElementById('cardsList');
    cardsList.innerHTML = '';
    
    if (cards.length === 0) {
        cardsList.innerHTML = '<div class="card-item">В этой колоде пока нет карточек</div>';
        return;
    }

    cards.forEach(card => {
        const cardItem = document.createElement('div');
        cardItem.className = 'card-item';
        cardItem.innerHTML = `
            <div class="card-question">${escapeHtml(card.question)}</div>
            <div class="card-answer">${escapeHtml(card.answer)}</div>
            <div class="card-stats">
                Повторений: ${card.repetitionCount || 0} | 
                Интервал: ${card.interval || 0}д | 
                След. повтор: ${formatNextReviewDate(card.nextReviewDate)}
            </div>
            <div class="card-actions">
                <button class="action-btn btn-danger" onclick="deleteCard('${card.id}')">Удалить</button>
            </div>
        `;
        cardsList.appendChild(cardItem);
    });
}

// Удаление карточки
async function deleteCard(cardId) {
    if (!confirm('Удалить эту карточку?')) return;

    try {
        await apiDeleteCard(cardId);
        cards = cards.filter(c => c.id !== cardId);
        updateCardsList();
        showNotification('Карточка удалена', 'success');
    } catch (error) {
        showNotification('Ошибка удаления: ' + error.message, 'error');
    }
}

// ==================== РЕЖИМ ПОВТОРЕНИЯ ====================

// Начало повторения
function startReview() {
    if (cards.length === 0) {
        showNotification('В колоде нет карточек для повторения!', 'error');
        return;
    }

// Фильтруем карточки, готовые к повторению
    reviewCards = cards.filter(card => {
        return !card.nextReviewDate  || new Date(card.nextReviewDate) <= new Date();
    });

    if (reviewCards.length === 0) {
        showNotification('Все карточки уже повторены! Возвращайтесь позже.', 'info');
        return;
    }

    // Перемешиваем карточки
    reviewCards = shuffleArray(reviewCards);
    currentReviewIndex = 0;
    isCardFlipped = false;
    
    // Переключаем режимы
    document.getElementById('deckSelected').classList.add('hidden');
    document.getElementById('reviewMode').classList.remove('hidden');
    
    showNextReviewCard();
}

// Показать следующую карточку для повторения
function showNextReviewCard() {
    if (currentReviewIndex >= reviewCards.length) {
        endReview();
        return;
    }

    const card = reviewCards[currentReviewIndex];
    document.getElementById('cardQuestionSide').textContent = card.question;
    document.getElementById('cardAnswerSide').textContent = card.answer;
    document.getElementById('cardAnswerSide').classList.add('hidden');
    
    document.getElementById('reviewProgress').textContent = 
        `${currentReviewIndex + 1}/${reviewCards.length}`;
    
    isCardFlipped = false;
}

// Переворот карточки
function flipCard() {
    isCardFlipped = !isCardFlipped;
    document.getElementById('cardAnswerSide').classList.toggle('hidden');
}

// Оценка карточки
async function rateCard(quality) {
    const card = reviewCards[currentReviewIndex];
    
    try {
        await apiUpdateCard(card.id, quality);
        currentReviewIndex++;
        showNextReviewCard();
    } catch (error) {
        showNotification('Ошибка обновления карточки: ' + error.message, 'error');
    }
}

// Выход из режима повторения
function exitReview() {
    document.getElementById('reviewMode').classList.add('hidden');
    document.getElementById('deckSelected').classList.remove('hidden');
    
    // Перезагружаем карточки для обновления статистики
    if (currentDeckId) {
        loadCards(currentDeckId);
    }
}

// Завершение повторения
function endReview() {
    showNotification('Повторение завершено! 🎉', 'success');
    exitReview();
}

// ==================== API ФУНКЦИИ ====================

async function apiCreateDeck(name, description) {
    const response = await fetch(API_CONFIG.baseUrl + API_CONFIG.endpoints.decks, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, description })
    });

    if (!response.ok) {
        const error = await response.text();
        throw new Error(error  || 'Ошибка сервера');
    }

    return await response.json();
}

async function apiCreateCard(deckId, question, answer) {
    const response = await fetch(API_CONFIG.baseUrl + API_CONFIG.endpoints.cards, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            deckId: deckId,
            question: question,
            answer: answer
        })
    });

    if (!response.ok) {
        const error = await response.text();
        throw new Error(error  || 'Ошибка сервера');
    }

    return await response.json();
}

async function apiUpdateCard(cardId, quality) {
    const response = await fetch(`${API_CONFIG.baseUrl}${API_CONFIG.endpoints.cards}/${cardId}/review`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ quality })
    });

    if (!response.ok) {
        const error = await response.text();
        throw new Error(error  || 'Ошибка сервера');
    }

    return await response.json();
}

async function apiDeleteDeck(_deckId) {
    const response = await fetch('${API_CONFIG.baseUrl}${API_CONFIG.endpoints.decks}/${deckId}', {
        method: 'DELETE'
    });

if (!response.ok) {
        const error = await response.text();
        throw new Error(error || 'Ошибка сервера');
    }
}

async function apiDeleteCard(cardId) {
    const response = await fetch(`${API_CONFIG.baseUrl}${API_CONFIG.endpoints.cards}/${cardId}`, {
        method: 'DELETE'
    });

    if (!response.ok) {
        const error = await response.text();
        throw new Error(error || 'Ошибка сервера');
    }
}

// ==================== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ====================

// Показать уведомление
function showNotification(message, type = 'info') {
    // Создаем временное уведомление
    const notification = document.createElement('div');
    notification.className = 'notification notification-${type}';
    notification.textContent = message;
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        padding: 12px 20px;
        border-radius: 8px;
        color: white;
        font-weight: 500;
        z-index: 1000;
        animation: slideIn 0.3s ease;
    `;

    const backgroundColor = {
        success: '#10B981',
        error: '#EF4444',
        info: '#6366F1'
    }[type] || '#6366F1';

    notification.style.backgroundColor = backgroundColor;

    document.body.appendChild(notification);

    // Автоматическое удаление через 3 секунды
    setTimeout(() => {
        notification.style.animation = 'slideOut 0.3s ease';
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 300);
    }, 3000);
}

// Экранирование HTML
function escapeHtml(unsafe) {
    return unsafe
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");
}

// Перемешивание массива
function shuffleArray(array) {
    const newArray = [...array];
    for (let i = newArray.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [newArray[i], newArray[j]] = [newArray[j], newArray[i]];
    }
    return newArray;
}

// Получение количества карточек в колоде
function getDeckCardCount(deckId) {
    return cards.filter(card => card.deckId === deckId).length;
}

// Форматирование даты следующего повторения
function formatNextReviewDate(dateString) {
    if (!dateString) return 'сегодня';
    
    const date = new Date(dateString);
    const today = new Date();
    const diffTime = date - today;
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    
    if (diffDays === 0) return 'сегодня';
    if (diffDays === 1) return 'завтра';
    if (diffDays === -1) return 'вчера';
    if (diffDays < 0) return 'просрочено';
    
    return `через ${diffDays} дн.`;
}

// Глобальные функции для HTML
globalThis.selectDeck = selectDeck;
globalThis.deleteDeck = deleteDeck;
globalThis.deleteCard = deleteCard;