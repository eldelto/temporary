let backendHost;

const hostname = window && window.location && window.location.hostname;

if(hostname === "www.eldelto.net") {
  backendHost = "https://www.eldelto.net/temporary";
} else {
  backendHost = process.env.REACT_APP_BACKEND_HOST || "http://localhost:4000";
}

export const API_ROOT = backendHost;