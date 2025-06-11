document.addEventListener('DOMContentLoaded', async () => {


    const statusElement = document.getElementById('status-text');
    const uninstallButton = document.getElementById('uninstall-button');
    const aboutButton = document.getElementById('about-button');
    const logOutput = document.getElementById('log-output');
    const aboutModal = document.getElementById('about-modal');
    const aboutCloseBtn = aboutModal.querySelector('.close-button');
    const confirmModal = document.getElementById('confirm-modal');
    const confirmUninstallBtn = document.getElementById('confirm-uninstall-btn');
    const cancelUninstallBtn = document.getElementById('cancel-uninstall-btn');
    const modulePath = "/data/adb/modules/SafetyCoreDisabler";

    async function runKsuCommand(command) {
        if (typeof ksu === 'undefined' || typeof ksu.exec !== 'function') {
            return { code: -1, stdout: "", stderr: "Error: KernelSU bridge not found." };
        }
        return new Promise((resolve) => {
            const callbackName = `scp_exec_callback_${Date.now()}_${Math.random().toString(36).substring(2)}`;
            window[callbackName] = (errno, stdout, stderr) => {
                delete window[callbackName];
                resolve({ code: errno, stdout: stdout || "", stderr: stderr || "" });
            };
            try { ksu.exec(command, JSON.stringify({}), callbackName); }
            catch (error) {
                delete window[callbackName];
                resolve({ code: -1, stdout: "", stderr: `Error initiating ksu.exec: ${error.message || error}` });
            }
        });
    }

    async function checkModuleStatus() {
        statusElement.textContent = "Checking status...";
        statusElement.style.color = "var(--secondary-text-color)";
        try {
            const response = await fetch(`module_files/status.log?t=${Date.now()}`);
            if (!response.ok) { throw new Error(`File not found! Status: ${response.status}`); }
            const result = await response.text();
            if (!result.trim()) { throw new Error("Log file is empty."); }
            const [status, message] = result.split(':', 2);
            switch (status.toUpperCase()) {
                case 'ACTIVE':
                    statusElement.innerHTML = `✅ ${message || 'Placeholder Active'}`;
                    statusElement.style.color = "var(--button-color)"; break;
                case 'WARNING':
                    statusElement.innerHTML = `⚠️ ${message || 'Warning issued'}`;
                    statusElement.style.color = "#FFEB3B"; break;
                case 'INACTIVE':
                    statusElement.innerHTML = `ℹ️ ${message || 'Inactive'}`;
                    statusElement.style.color = "var(--secondary-text-color)"; break;
                default:
                    statusElement.innerHTML = `❌ ${message || 'An error occurred'}`;
                    statusElement.style.color = "#F44336"; break;
            }
        } catch (error) {
            console.error('Failed to fetch status log:', error);
            statusElement.innerHTML = `❌ Failed to read status file. Reinstall the module.`;
            statusElement.style.color = "#F44336";
        }
    }

    if (uninstallButton) {
        uninstallButton.addEventListener('click', () => {
            if(confirmModal) confirmModal.style.display = "block";
        });
    }

    if (cancelUninstallBtn) {
        cancelUninstallBtn.addEventListener('click', () => {
            if(confirmModal) confirmModal.style.display = "none";
        });
    }
    
    if (confirmUninstallBtn && logOutput) {
        confirmUninstallBtn.addEventListener('click', async () => {
            if(confirmModal) confirmModal.style.display = "none";
            logOutput.style.display = 'block';
            logOutput.textContent = 'User confirmed. Scheduling uninstall task...\n\n';
            
            try {
                const result = await runKsuCommand(`sh ${modulePath}/uninstall.sh`);

                logOutput.textContent += '--- SCRIPT OUTPUT ---\n';
                logOutput.textContent += result.stdout || '(No output from script)';
                if (result.code !== 0) {
                     logOutput.textContent += `\n--- SCRIPT FAILED ---\n${result.stderr}`;
                }

            } catch (error) {
                logOutput.textContent += `--- FATAL ERROR ---\nCould not execute the shell command. The bridge may have failed.\nError: ${error}`;
            }
        });
    }

    if (aboutButton && aboutModal && aboutCloseBtn) {
        aboutButton.onclick = () => { aboutModal.style.display = "block"; };
        aboutCloseBtn.onclick = () => { aboutModal.style.display = "none"; };
    }
    
    window.onclick = (event) => {
        if (event.target == aboutModal) aboutModal.style.display = "none";
        if (event.target == confirmModal) confirmModal.style.display = "none";
    };

    checkModuleStatus();
});
