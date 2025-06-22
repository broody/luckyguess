import { BrowserRouter as Router, Routes, Route } from "react-router-dom";

import {
  StarknetConfig,
  voyager,
  jsonRpcProvider,
  Connector,
} from "@starknet-react/core";
import { Chain, sepolia, mainnet } from "@starknet-react/chains";
import { constants } from "starknet";
import { ControllerOptions, ProfileOptions } from "@cartridge/controller";
import ControllerConnector from "@cartridge/connector/controller";
import Home from "./Home";

const provider = jsonRpcProvider({
  rpc: (chain: Chain) => {
    switch (chain) {
      case mainnet:
        return { nodeUrl: import.meta.env.VITE_MAINNET_RPC_URL };
      case sepolia:
        return { nodeUrl: import.meta.env.VITE_SEPOLIA_RPC_URL };
      default:
        throw new Error(`Unsupported chain: ${chain.network}`);
    }
  },
});

const profile: ProfileOptions = {
  preset: "eternum",
  slot: "nums-mainnet-appchain",
  namespace: "nums",
};

const options: ControllerOptions = {
  ...profile,
  defaultChainId: constants.StarknetChainId.SN_MAIN,
  chains: [
    { rpcUrl: import.meta.env.VITE_MAINNET_RPC_URL },
    { rpcUrl: import.meta.env.VITE_SEPOLIA_RPC_URL },
  ],
  tokens: {
    erc20: [import.meta.env.VITE_NUMS_ERC20],
  },
  url: "https://keychain-git-retry-disable-sp.preview.cartridge.gg",
};

const connectors = [new ControllerConnector(options) as never as Connector];

export const App = () => {
  return (
    <StarknetConfig
      autoConnect
      chains={[mainnet, sepolia]}
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
