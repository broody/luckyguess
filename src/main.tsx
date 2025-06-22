import React from "react";
import ReactDOM from "react-dom/client";
import { ChakraProvider } from "@chakra-ui/react";
import theme from "./theme";
import { inject } from "@vercel/analytics";

inject();

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <ChakraProvider value={theme}>
      <></>
    </ChakraProvider>
  </React.StrictMode>,
);
