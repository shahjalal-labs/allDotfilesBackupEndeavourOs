from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.connect_over_cdp("http://localhost:9222")
    context = browser.contexts[0]

    for page in context.pages:
        if "linkedin.com" in page.url:
            print(f"Closing: {page.title()} ({page.url})")
            page.close()

