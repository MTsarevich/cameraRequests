/*
 * LinkUP — интеграция форм сайта linkup.by с приложением приёма заявок.
 *
 * КУДА ВСТАВИТЬ: скопировать содержимое этого файла в конец `assets/script.js`
 * сайта linkup.by (или подключить отдельным <script> на каждой странице с формой).
 *
 * ЧТО ДЕЛАЕТ: при отправке любой из 4 форм сайта дублирует заявку в приложение
 * LinkUP (POST на Vercel-эндпоинт). Существующую отправку в Telegram НЕ трогает —
 * работает параллельно.
 *
 * Покрываемые точки заявок:
 *   1. Главная форма в футере (#leadForm / #submitBtn) ........ source: website
 *   2. Модалка «Заказать звонок» (sendCallbackRequest) ........ source: callback
 *   3. Модалка «Отправить проект/ТЗ» (#projectSubmitBtn) ...... source: project
 *   4. Модалка «Калькулятор» (sendCalcLead) .................. source: calculator
 *
 * Бэкенд сам нормализует телефон и делает дедуп (повторная отправка того же
 * номера в пределах 15 секунд склеивается в одну заявку).
 */
(function () {
  var ENDPOINT = "https://camera-requests.vercel.app/api/ingestLead";
  var SECRET = "e99035e9a248526737e5ccc8ccf59a5c";

  function send(payload) {
    payload.pageUrl = location.href;
    fetch(ENDPOINT, {
      method: "POST",
      keepalive: true,
      headers: { "Content-Type": "application/json", "X-Ingest-Secret": SECRET },
      body: JSON.stringify(payload)
    }).catch(function () {});
  }

  function val(id) {
    var el = document.getElementById(id);
    return el ? (el.value || "").trim() : "";
  }

  document.addEventListener("click", function (e) {
    var btn = e.target.closest && e.target.closest("button");
    if (!btn) return;
    var onclick = btn.getAttribute("onclick") || "";

    // 1) Главная форма заявки (футер)
    if (btn.id === "submitBtn") {
      var n = val("name"), p = val("phone");
      if (!n && !p) return;
      send({ name: n, phone: p, email: val("email"), message: val("comment"), source: "website" });
      return;
    }

    // 2) Модалка «Заказать звонок»
    if (onclick.indexOf("sendCallbackRequest") !== -1) {
      var cb = val("callbackPhone");
      if (!cb) return;
      send({ phone: cb, source: "callback" });
      return;
    }

    // 3) Модалка «Отправить проект / ТЗ»
    if (btn.id === "projectSubmitBtn") {
      var pn = val("projectName"), pp = val("projectPhone");
      if (!pn && !pp) return;
      send({ name: pn, phone: pp, message: "Заявка с загрузкой проекта / ТЗ", source: "project" });
      return;
    }

    // 4) Модалка «Калькулятор»
    if (onclick.indexOf("sendCalcLead") !== -1) {
      var cn = val("calcName"), cp = val("calcPhone");
      if (!cn && !cp) return;
      var m = onclick.match(/sendCalcLead\(\s*(\d+)/);
      var msg = m ? ("Калькулятор: примерная стоимость ~" + m[1] + " BYN") : "Заявка из калькулятора";
      send({ name: cn, phone: cp, message: msg, source: "calculator" });
      return;
    }
  }, true);
})();
