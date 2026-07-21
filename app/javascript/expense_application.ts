import { Application } from "@hotwired/stimulus";
import ExpenseAppController from "./controllers/expense_app_controller";
import { parseQuickExpense } from "./expenses/parser";

const application = Application.start();
application.register("expense-app", ExpenseAppController);

if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("/service-worker");
  });
}

export { parseQuickExpense };
