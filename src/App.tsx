import { BrowserRouter as Router, Routes, Route } from "react-router-dom";

import {
  StarknetConfig,
  voyager,
  jsonRpcProvider,
  Connector,
} from "@starknet-react/core";
import { Chain, sepolia, mainnet } from "@starknet-react/chains";
import { constants } from "starknet";
import { ControllerOptions } from "@cartridge/controller";
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

const options: ControllerOptions = {
  defaultChainId: constants.StarknetChainId.SN_SEPOLIA,
  policies: {
    contracts: {
      "0x06d20a3da66fe430ab62e5e39c14c87a4a197929020e0758bd6de24f8025df53": {
        methods: [
          {
            entrypoint: "flip_coin",
            description: "Flip a coin",
          },
        ],
      },
      "0x051fea4450da9d6aee758bdeba88b2f665bcbf549d2c61421aa724e9ac0ced8f": {
        methods: [
          {
            entrypoint: "request_random",
            description: "Request random",
          },
        ],
      },
    },
  },
  chains: [
    { rpcUrl: import.meta.env.VITE_MAINNET_RPC_URL },
    { rpcUrl: import.meta.env.VITE_SEPOLIA_RPC_URL },
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
