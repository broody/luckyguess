import { BrowserRouter as Router, Routes, Route } from "react-router-dom";

import {
  StarknetConfig,
  voyager,
  jsonRpcProvider,
  Connector,
} from "@starknet-react/core";
import { Chain, sepolia, mainnet } from "@starknet-react/chains";
import { constants, num, shortString } from "starknet";
import { ControllerOptions, ProfileOptions } from "@cartridge/controller";
import ControllerConnector from "@cartridge/connector/controller";
import Home from "./Home";

const slot: Chain = {
  id: num.toBigInt(shortString.encodeShortString("WP_LUCKYGUESS")),
  network: "luckyguess",
  name: "Lucky Guess",
  rpcUrls: {
    default: import.meta.env.VITE_LUCKYGUESS_RPC_URL,
    public: import.meta.env.VITE_LUCKYGUESS_RPC_URL,
  },
  nativeCurrency: {
    name: "Ethereum",
    symbol: "ETH",
    decimals: 18,
    address: import.meta.env.VITE_ETH_ADDRESS,
  },
};

const provider = jsonRpcProvider({
  rpc: (chain: Chain) => {
    switch (chain) {
      case mainnet:
        return { nodeUrl: import.meta.env.VITE_MAINNET_RPC_URL };
      case sepolia:
        return { nodeUrl: import.meta.env.VITE_SEPOLIA_RPC_URL };
      case slot:
        return { nodeUrl: import.meta.env.VITE_LUCKYGUESS_RPC_URL };
      default:
        throw new Error(`Unsupported chain: ${chain.network}`);
    }
  },
});



const options: ControllerOptions = {
  defaultChainId: shortString.encodeShortString("WP_LUCKYGUESS"),
  chains: [
    { rpcUrl: import.meta.env.VITE_MAINNET_RPC_URL },
    { rpcUrl: import.meta.env.VITE_SEPOLIA_RPC_URL },
    { rpcUrl: import.meta.env.VITE_LUCKYGUESS_RPC_URL },
  ],
  tokens: {
    erc20: [import.meta.env.VITE_NUMS_ERC20],
  },
};

const connectors = [new ControllerConnector(options) as never as Connector];

export const App = () => {
  return (
    <StarknetConfig
      autoConnect
      chains={[slot]}
      connectors={connectors}
      provider={provider}
      explorer={voyager}
    >
      <Router>
        <Routes>
          <Route path="/" element={<Home />} />
        </Routes>
      </Router>
    </StarknetConfig>
  );
};
