import { defineConfig, devices } from "@playwright/test";

const playwrightPort = process.env.PLAYWRIGHT_PORT || "3200";
const baseURL = `http://127.0.0.1:${playwrightPort}`;

export default defineConfig({
  testDir: "./tests",
  timeout: 20 * 1000,
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [["list"], ["html", { open: "never" }]],
  use: {
    headless: !process.env.PLAYWRIGHT_HEADED,
    trace: "on-first-retry",
    baseURL,
    actionTimeout: 10 * 1000,
    navigationTimeout: 15 * 1000,
    locale: "de-DE",
    timezoneId: "Europe/Berlin",
    extraHTTPHeaders: {
      "Accept-Language": "de-DE,de;q=0.9,en;q=0.8"
    },
    launchOptions: {
      args: ["--lang=de-DE"]
    }
  },
  projects: [
    {
      name: "chromium",
      use: {
        ...devices["Desktop Chrome"]
      }
    }
  ],
  webServer: process.env.PLAYWRIGHT_SKIP_WEBSERVER
    ? undefined
    : {
        command: `RAILS_ENV=test bin/rails db:prepare && RAILS_ENV=test bin/rails runner 'user = User.find_or_initialize_by(email_address: "expense-e2e@example.com"); user.password = "password"; user.locale = "en" if user.respond_to?(:locale=); user.save!; member = User.find_or_initialize_by(email_address: "expense-member-e2e@example.com"); member.password = "password"; member.locale = "en" if member.respond_to?(:locale=); member.save!; Trip.where(name: "Playwright Expense Trip", user: user).destroy_all; trip = Trip.create!(user: user, name: "Playwright Expense Trip", start_date: Date.current, end_date: Date.current + 2.days); trip.add_member(member); trip.trip_person_for(user); trip.trip_person_for(member)' && RAILS_ENV=test bin/rails server -b 127.0.0.1 -p ${playwrightPort}`,
        url: baseURL,
        reuseExistingServer: false,
        timeout: 45 * 1000
      }
});
