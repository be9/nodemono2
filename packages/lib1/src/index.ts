import puppeteer from 'puppeteer'

export async function getPuppeteerVersion(): Promise<string> {
  const browser = await puppeteer.launch({
    // Cut some corners
    // https://pptr.dev/troubleshooting#setting-up-chrome-linux-sandbox
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });
  const version = await browser.version();
  await browser.close();

  return version;
}
