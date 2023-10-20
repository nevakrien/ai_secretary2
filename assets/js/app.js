// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())


// connect if there are any LiveViews on the page
liveSocket.connect()
liveSocket.enableDebug()
// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

window.addEventListener("scrollIntoView", event => {
  event.target.scrollIntoView({behavior: "smooth"})
})

let Hooks = {};

// Hooks.SendTime = {
//   mounted() {
//     // 'this' refers to the Hook's context, and 'this.el' is the DOM element the Hook is attached to.
//     // You don't need to know the specific ID of the element.
//     this.pushEvent("receive_time", { current_time: new Date().toISOString() });
//   },
// };

Hooks.SendTime = {
  mounted() {
     console.log("SendTime hook mounted!"); 
    let now = new Date();
    let tzOffset = now.getTimezoneOffset() * 60000; //offset in milliseconds
    let localISOTime = (new Date(now - tzOffset)).toISOString().slice(0, -1);

    // Remove milliseconds
    let finalTime = localISOTime.split('.')[0];

    this.pushEvent("receive_time", { current_time: finalTime });
  },
};




// Assuming liveSocket is your LiveSocket instance
liveSocket.hooks = Hooks;


