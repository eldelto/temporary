let backendHost;

const hostname = window && window.location && window.location.hostname;

if(hostname === "temporary.eldelto.net") {
  backendHost = "https://temporary.eldelto.net";
} else {
  backendHost = process.env.REACT_APP_BACKEND_HOST || "http://localhost:4000";
}

export const API_ROOT = backendHost;