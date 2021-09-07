import { stableMap } from "../../declarations/stableMap";

document.getElementById("clickMeBtn").addEventListener("click", async () => {
  const name = document.getElementById("name").value.toString();
  // Interact with stableMap actor, calling the greet method
  const greeting = await stableMap.greet(name);

  document.getElementById("greeting").innerText = greeting;
});
