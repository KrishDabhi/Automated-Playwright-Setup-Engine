const { chromium } = require('playwright');
const fs = require('fs');

const SUPPORTED_ACTIONS = [
    'goto',
    'click',
    'clickFirst',
    'fill',
    'wait',
    'waitForSelector',
    'verifyText',
    'scrollToText',
    'scrollToSelector',
    'clickProductByPriceRange'
];

function validateSteps(steps) {
    if (!Array.isArray(steps) || steps.length === 0) {
        throw new Error("Task must be a non-empty array.");
    }
    if (steps[0].action !== 'goto') {
        throw new Error("First step must be 'goto'.");
    }
    steps.forEach((step, index) => {
        if (!step.action) {
            throw new Error(`Step ${index}: Missing 'action'.`);
        }
        if (!SUPPORTED_ACTIONS.includes(step.action)) {
            throw new Error(`Step ${index}: Unsupported action '${step.action}'.`);
        }
        if (['click', 'clickFirst', 'fill', 'waitForSelector', 'scrollToSelector'].includes(step.action) && (step.selector === undefined || step.selector === null)) {
            throw new Error(`Step ${index}: 'selector' is required.`);
        }
        if (['goto', 'wait', 'verifyText', 'scrollToText'].includes(step.action) && step.value === undefined) {
            throw new Error(`Step ${index}: 'value' is required.`);
        }
        if (step.action === 'wait' && typeof step.value !== 'number') {
            throw new Error(`Step ${index}: 'wait' requires numeric milliseconds.`);
        }
    });
    console.log("✅ Validation passed.");
}

async function executeSteps(steps) {
    const browser = await chromium.launch({ headless: false });
    const page = await browser.newPage();
    for (let i = 0; i < steps.length; i++) {
        const step = steps[i];
        console.log(`▶ Step ${i + 1}:`, step);
        try {
            switch (step.action) {
                case 'goto':
                    await page.goto(step.value, { waitUntil: 'networkidle' });
                    break;
                case 'click':
                    await page.waitForSelector(step.selector, { timeout: 20000 });
                    await page.click(step.selector);
                    break;
                case 'clickFirst':
                    await page.waitForSelector(step.selector, { timeout: 20000 });
                    const elements = await page.$$(step.selector);
                    if (!elements.length) throw new Error(`No elements found for selector: ${step.selector}`);
                    await elements[0].click();
                    break;
                case 'fill': {
                    if (typeof step.selector === 'string') {
                        const input = page.locator(step.selector);
                        await input.click();
                        await input.fill(step.value);
                    } else {
                        const inputs = page.locator('input:visible');
                        const count = await inputs.count();
                        if (step.selector >= count) throw new Error(`Input index ${step.selector} not found`);
                        const input = inputs.nth(step.selector);
                        await input.click();
                        await input.fill(step.value);
                    }
                    break;
                }
                case 'wait':
                    await page.waitForTimeout(step.value);
                    break;
                case 'waitForSelector':
                    await page.waitForSelector(step.selector, { timeout: 20000 });
                    break;
                case 'verifyText':
                    await page.waitForFunction((text) => document.body.innerText.includes(text), step.value, { timeout: 20000 });
                    break;
                case 'scrollToText':
                    await page.evaluate((text) => {
                        const el = [...document.querySelectorAll('*')].find(e => e.innerText && e.innerText.includes(text));
                        if (el) el.scrollIntoView({ behavior: 'smooth', block: 'center' });
                    }, step.value);
                    break;
                case 'scrollToSelector':
                    await page.evaluate((selector) => {
                        const el = document.querySelector(selector);
                        if (el) el.scrollIntoView({ behavior: 'smooth', block: 'center' });
                    }, step.selector);
                    break;
                case 'clickProductByPriceRange': {
                    const { min, max } = step;
                    const products = await page.$$('.products .product');
                    let clicked = false;
                    for (const product of products) {
                        const priceElement = await product.$('.price');
                        if (!priceElement) continue;
                        const priceText = await priceElement.innerText();
                        const price = parseFloat(priceText.replace(/[^0-9.]/g, ''));
                        if (!isNaN(price) && price >= min && price <= max) {
                            const btn = await product.$('a');
                            if (btn) {
                                await btn.click();
                                clicked = true;
                                break;
                            }
                        }
                    }
                    if (!clicked) throw new Error(`No product found in price range ${min}-${max}`);
                    break;
                }
            }
        } catch (err) {
            console.error("❌ Execution failed at step:", step);
            console.error("Reason:", err.message);
            await browser.close();
            process.exit(1);
        }
    }
    console.log("🎉 Flow completed successfully.");
}

(async () => {
    try {
        const taskFile = process.argv[2] || './task.json';
        const raw = fs.readFileSync(taskFile);
        const steps = JSON.parse(raw);
        validateSteps(steps);
        await executeSteps(steps);
    } catch (err) {
        console.error("❌ Fatal Error:", err.message);
        process.exit(1);
    }
})();
