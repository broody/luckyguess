import { Box, HStack, Image, Input, Text, VStack } from "@chakra-ui/react";
import { useState } from "react";

import { Button } from "./Button";
import { useAccount, useConnect } from "@starknet-react/core";
import { cairo, CallData, stark, Uint256 } from "starknet";

const Controls = ({
  flip,
  toggleWobble,
  reset,
}: {
  flip: (isHeads: boolean) => void;
  toggleWobble: (wobble: boolean) => void;
  reset: () => void;
}) => {
  const [betSize, setBetSize] = useState(1);
  const [selected, setSelected] = useState<"heads" | "tails" | null>(null);
  const [gameState, setGameState] = useState<"idle" | "flipping" | "results">(
    "idle",
  );
  const [gameResult, setGameResult] = useState<"won" | "lost" | null>(null);
  const { connect, connectors } = useConnect();
  const { account } = useAccount();

  const executeFlip = async (selectedHeads: boolean) => {
    console.log("selected", selectedHeads ? "heads" : "tails");
    if (!account) {
      return;
    }

    setSelected(selectedHeads ? "heads" : "tails");
    setGameState("flipping");
    toggleWobble(true);

    const randomHash = stark.randomAddress();
    const bet: Uint256 = cairo.uint256(BigInt(betSize) * 10n ** 18n);
    const { transaction_hash } = await account.execute([
      {
        contractAddress: import.meta.env.VITE_VRF_CONTRACT,
        entrypoint: "request_random",
        calldata: CallData.compile({
          caller: import.meta.env.VITE_GAME_CONTRACT,
          source: { type: 0, address: account.address },
        }),
      },
      {
        contractAddress: import.meta.env.VITE_GAME_CONTRACT,
        entrypoint: "flip_coin",
        calldata: CallData.compile([randomHash, bet, selectedHeads ? 1 : 0]),
      },
    ]);

    const receipt = await account.waitForTransaction(transaction_hash, {
      retryInterval: 500,
    });

    if (receipt.isSuccess()) {
      const won = receipt.events[3].data[8] === "0x1";
      const isHeads = receipt.events[3].data[7] === "0x1";
      setGameResult(won ? "won" : "lost");
      flip(isHeads);
    }

    toggleWobble(false);

    setTimeout(() => {
      setGameState("results");
    }, 2500);
  };

  const resetGame = () => {
    setGameState("idle");
    setSelected(null);
    setGameResult(null);
    reset();
  };

  return (
    <Box
      position="fixed"
      w={["calc(100% - 100px)", "calc(100% - 100px)", "600px"]}
      h={["30%", "35%", "250px"]}
      bottom="40px"
      left="50%"
      transform="translateX(-50%)"
      zIndex={10}
    >
      <Box
        boxSize="100%"
        bg="#2e502e"
        borderRadius="12px"
        p="20px"
        boxShadow="0 4px 8px rgba(0,0,0,0.3)"
        display="flex"
        flexDir="column"
        justifyContent="flex-start"
        alignItems="center"
      >
        {account ? (
          <>
            <VStack w="full" justify="space-between" gap="0" h="100%">
              <VStack>
                <Text color="#759a58" fontSize="18px" fontWeight="bold">
                  {gameState === "idle" && "Select"}
                  {gameState === "flipping" && "Flipping"}
                  {gameState === "results" &&
                    (gameResult === "won" ? "You Won!" : "You Lost!")}
                </Text>
                <HStack w="full" justify="center" position="relative">
                  <Image
                    src="/coin_face.png"
                    boxSize="90px"
                    cursor="pointer"
                    transition="all 0.5s cubic-bezier(0.4, 0, 0.2, 1)"
                    _hover={{ scale: selected === null ? 1.1 : 1 }}
                    opacity={selected === "tails" ? 0 : 1}
                    transform={
                      selected === "heads"
                        ? "translateX(50px)"
                        : "translateX(0)"
                    }
                    onClick={() => {
                      if (gameState === "flipping") return;
                      if (gameState === "results") {
                        resetGame();
                        return;
                      }
                      selected === "heads"
                        ? setSelected(null)
                        : executeFlip(true);
                    }}
                    pointerEvents={
                      selected === "tails" || gameState === "flipping"
                        ? "none"
                        : "auto"
                    }
                  />
                  <Image
                    src="/coin_butt.png"
                    boxSize="100px"
                    cursor="pointer"
                    transition="all 0.5s cubic-bezier(0.4, 0, 0.2, 1)"
                    _hover={{ scale: selected === null ? 1.1 : 1 }}
                    opacity={selected === "heads" ? 0 : 1}
                    transform={
                      selected === "tails"
                        ? "translateX(-50px)"
                        : "translateX(0)"
                    }
                    onClick={() => {
                      if (gameState === "flipping") return;
                      if (gameState === "results") {
                        resetGame();
                        return;
                      }
                      selected === "tails"
                        ? setSelected(null)
                        : executeFlip(false);
                    }}
                    pointerEvents={
                      selected === "heads" || gameState === "flipping"
                        ? "none"
                        : "auto"
                    }
                  />
                </HStack>
              </VStack>
              {gameState !== "results" && (
                <VStack>
                  <Text fontSize="18px" fontWeight="bold" color="#759a58">
                    Bet Size{" "}
                  </Text>
                  <HStack>
                    <Input
                      borderColor="#133217"
                      backgroundColor="#133217"
                      type="number"
                      value={betSize}
                      onChange={(e) => {
                        setBetSize(Number(e.target.value));
                      }}
                      h="40px"
                      w="100px"
                      disabled={gameState === "flipping"}
                    />
                    <Button
                      h="40px"
                      borderRadius="4px"
                      fontSize="18px"
                      fontWeight="bold"
                      border="1px solid #759a58"
                      _hover={{ bg: "#133217", color: "#759a58" }}
                      disabled={gameState === "flipping"}
                    >
                      $STRK
                    </Button>
                  </HStack>
                </VStack>
              )}
              {gameState === "results" && (
                <Button
                  onClick={resetGame}
                  h="40px"
                  borderRadius="8px"
                  fontSize="20px"
                  fontWeight="bold"
                  bg="#759a58"
                  _hover={{ bg: "#5a7a43" }}
                  _active={{ bg: "#4a6a33" }}
                >
                  Retry
                </Button>
              )}
            </VStack>
          </>
        ) : (
          <Button
            onClick={() => {
              connect({ connector: connectors[0] });
            }}
          >
            Connect
          </Button>
        )}
      </Box>
    </Box>
  );
};

export default Controls;
