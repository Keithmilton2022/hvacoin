// Connect Wallet Button Functionality
document.getElementById('connectWallet').addEventListener('click', async function() {
    if (window.ethereum) {
        try {
            const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
            alert(`Connected to wallet: ${accounts[0]}`);
        } catch (error) {
            console.error(error);
            alert('Connection to wallet failed.');
        }
    } else {
        alert('Please install MetaMask!');
    }
});

// Countdown Timer for Presale
function startCountdown(endTime) {
    const timerElement = document.getElementById('timer');
    const interval = setInterval(function() {
        const now = new Date().getTime();
        const distance = endTime - now;

        if (distance <= 0) {
            clearInterval(interval);
            timerElement.innerHTML = "Presale Ended";
        } else {
            const hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
            const minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
            const seconds = Math.floor((distance % (1000 * 60)) / 1000);

            timerElement.innerHTML = `${hours}h ${minutes}m ${seconds}s`;
        }
    }, 1000);
}

// Example presale end time (set to 1 minute from now)
const presaleEndTime = new Date().getTime() + 1 * 60 * 1000;
startCountdown(presaleEndTime);
