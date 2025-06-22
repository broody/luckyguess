import {
  Box,
  Container,
  HStack,
  Image,
  Input,
  Text,
  VStack,
} from "@chakra-ui/react";
import { useEffect, useRef, useState } from "react";
import * as THREE from "three";
import * as CANNON from "cannon-es";
import { Button } from "./components/Button";

const Home = () => {
  const mountRef = useRef<HTMLDivElement>(null);
  const flipCoinRef = useRef<(() => void) | null>(null);

  useEffect(() => {
    if (!mountRef.current) {
      return;
    }

    const currentMount = mountRef.current;

    // Scene
    const scene = new THREE.Scene();
    scene.background = new THREE.Color(0x6f955f);
    scene.fog = new THREE.Fog(0x6f955f, 10, 250);

    // Physics World
    const world = new CANNON.World();
    world.gravity.set(0, -2, 0);
    world.broadphase = new CANNON.NaiveBroadphase();

    // Lights
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.5);
    scene.add(ambientLight);

    const directionalLight = new THREE.DirectionalLight(0xffffff, 1);
    directionalLight.position.set(5, 10, 7.5);
    directionalLight.castShadow = true;
    scene.add(directionalLight);

    // Camera
    const camera = new THREE.PerspectiveCamera(
      75,
      window.innerWidth / window.innerHeight,
      0.1,
      1000,
    );
    camera.position.set(0, 3, 4); // Position the camera to see the coin flip
    camera.lookAt(0, 1, 1); // Look at the coin area

    // Renderer
    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2)); // High DPI support

    currentMount.appendChild(renderer.domElement);

    // Plane (Ground)
    const planeGeometry = new THREE.PlaneGeometry(500, 500);
    const planeMaterial = new THREE.MeshToonMaterial({
      color: 0x7a9c53,
    });
    const plane = new THREE.Mesh(planeGeometry, planeMaterial);
    plane.rotation.x = -Math.PI / 2;
    plane.position.y = 0;
    plane.receiveShadow = true;
    scene.add(plane);

    // Physics Ground
    const groundShape = new CANNON.Plane();
    const groundBody = new CANNON.Body({ mass: 0 }); // mass 0 = static
    groundBody.addShape(groundShape);
    groundBody.quaternion.setFromAxisAngle(
      new CANNON.Vec3(1, 0, 0),
      -Math.PI / 2,
    );
    world.addBody(groundBody);

    // Coin with rounded edges - using higher segment count for smoother edges
    const coinGeometry = new THREE.CylinderGeometry(
      0.4, // top radius
      0.4, // bottom radius
      0.1, // height
      32, // radial segments (more = smoother)
      1, // height segments
      false, // open ended
      0, // theta start
      Math.PI * 2, // theta length
    );

    // Load texture for heads side
    const textureLoader = new THREE.TextureLoader();
    const headsTexture = textureLoader.load("/heads.png");
    const tailsTexture = textureLoader.load("/tails.png");

    // Make the texture sharp and crisp
    headsTexture.magFilter = THREE.NearestFilter; // Sharp when zoomed in
    headsTexture.minFilter = THREE.NearestFilter; // Sharp when zoomed out
    headsTexture.generateMipmaps = false; // Disable mipmaps for sharper look
    headsTexture.wrapS = THREE.ClampToEdgeWrapping;
    headsTexture.wrapT = THREE.ClampToEdgeWrapping;

    // Rotate texture 90 degrees to the left
    headsTexture.rotation = Math.PI / 2;
    headsTexture.center.set(0.5, 0.5); // Set rotation center

    // Create materials for different parts of the coin
    const headsMaterial = new THREE.MeshBasicMaterial({
      map: headsTexture,
      color: 0xffd700, // Gold background color
    });

    const tailsMaterial = new THREE.MeshBasicMaterial({
      map: tailsTexture,
      color: 0xffd700,
    });

    const edgeMaterial = new THREE.MeshBasicMaterial({
      color: 0xdaa520, // Darker gold for the edge
    });

    // Create materials array: edge, top (heads), bottom (tails)
    const coinMaterials = [
      edgeMaterial, // Side of cylinder
      headsMaterial, // Top face (heads)
      tailsMaterial, // Bottom face (tails)
    ];

    const coin = new THREE.Mesh(coinGeometry, coinMaterials);
    coin.position.set(0, 0, 0); // Start higher up
    coin.castShadow = true;
    scene.add(coin);

    // Add black outline/stroke to the coin
    const edgesGeometry = new THREE.EdgesGeometry(coinGeometry);
    const edgesMaterial = new THREE.LineBasicMaterial({
      color: 0x222222,
      linewidth: 1,
    });
    const coinOutline = new THREE.LineSegments(edgesGeometry, edgesMaterial);
    coinOutline.position.copy(coin.position);
    scene.add(coinOutline);

    // Physics Coin
    const coinShape = new CANNON.Cylinder(0.4, 0.4, 0.2, 8);
    const coinBody = new CANNON.Body({ mass: 1 });
    coinBody.addShape(coinShape);
    coinBody.position.set(0, 0.5, 0);

    // Add some material properties for deterministic landing
    const coinMat = new CANNON.Material();
    const groundMat = new CANNON.Material();
    const coinGroundContact = new CANNON.ContactMaterial(coinMat, groundMat, {
      friction: 1,
      restitution: 0, // No bouncing
    });
    world.addContactMaterial(coinGroundContact);
    coinBody.material = coinMat;
    groundBody.material = groundMat;

    world.addBody(coinBody);

    // Raycaster for click detection
    const raycaster = new THREE.Raycaster();
    const mouse = new THREE.Vector2();

    // Coin flip function that can be called from anywhere
    const flipCoin = () => {
      const flipForce = 3;

      // Reset position and velocity
      coinBody.position.set(0, 0.4, 0);
      coinBody.velocity.set(0, 0, 0);
      coinBody.quaternion.set(0, 0, 0, 1);
      coinBody.angularVelocity.set(10, 4, 0); //heads

      // Apply upward force
      coinBody.velocity.set(0, flipForce, 0);
    };

    // Store the flipCoin function in the ref so it can be accessed outside useEffect
    flipCoinRef.current = flipCoin;

    const handleClick = (event: MouseEvent) => {
      // Calculate mouse position in normalized device coordinates
      mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
      mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;

      // Update the picking ray with the camera and mouse position
      raycaster.setFromCamera(mouse, camera);

      // Calculate objects intersecting the picking ray
      const intersects = raycaster.intersectObjects([coin]);

      if (intersects.length > 0) {
        flipCoin();
      }
    };

    const handleResize = () => {
      camera.aspect = window.innerWidth / window.innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(window.innerWidth, window.innerHeight);
    };

    window.addEventListener("resize", handleResize);

    const animate = () => {
      requestAnimationFrame(animate);

      // Use fixed timestep for deterministic physics
      const fixedTimeStep = 1 / 60;

      // Step the physics world
      world.step(fixedTimeStep);

      // Update coin position and rotation from physics
      coin.position.copy(coinBody.position as any);
      coin.quaternion.copy(coinBody.quaternion as any);

      // Update outline to match coin position and rotation
      coinOutline.position.copy(coin.position);
      coinOutline.quaternion.copy(coin.quaternion);

      renderer.render(scene, camera);
    };

    animate();

    // Cleanup
    return () => {
      window.removeEventListener("resize", handleResize);
      window.removeEventListener("click", handleClick);
      if (currentMount) {
        currentMount.removeChild(renderer.domElement);
      }
    };
  }, []);

  return (
    <Container
      position="relative"
      w="100vw"
      h="100vh"
      bg="red"
      minH="100vh"
      maxW="100vw"
      display="flex"
      justifyContent="center"
      alignItems={["flex-start", "flex-start", "center"]}
      p="15px"
      pt={["100px", "100px", "40px"]}
    >
      <Box
        ref={mountRef}
        w="100vw"
        h="100vh"
        position="absolute"
        top={0}
        left={0}
      />
      <Controls flip={() => flipCoinRef.current?.()} />
    </Container>
  );
};

const Controls = ({ flip }: { flip: (isHeads: boolean) => void }) => {
  const [betSize, setBetSize] = useState(1);
  const [selected, setSelected] = useState<"heads" | "tails" | null>(null);
  return (
    <Box
      position="fixed"
      w={["calc(100% - 100px)", "calc(100% - 100px)", "600px"]}
      h={["30%", "35%", "20%"]}
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
      >
        <VStack w="full" justify="center" gap="0">
          <Text color="#759a58" fontSize="18px" fontWeight="bold">
            Select
          </Text>
          <HStack w="full" justify="center">
            <Image
              src="/coin_face.png"
              boxSize="90px"
              cursor="pointer"
              transition="all 0.2s ease-in-out"
              _hover={{ scale: 1.1 }}
              opacity={selected === "heads" || selected === null ? 1 : 0.5}
              onClick={() => {
                setSelected("heads");
                flip(true);
              }}
            />
            <Image
              src="/coin_butt.png"
              boxSize="100px"
              cursor="pointer"
              transition="all 0.2s ease-in-out"
              _hover={{ scale: 1.1 }}
              opacity={selected === "tails" || selected === null ? 1 : 0.5}
              onClick={() => {
                setSelected("tails");
                flip(false);
              }}
            />
          </HStack>
          <VStack>
            <Text fontSize="18px" fontWeight="bold" color="#759a58">Bet Size </Text>
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
            />
              <Button h="40px" borderRadius="4px" fontSize="18px" fontWeight="bold" border="1px solid #759a58" _hover={{ bg: "#133217", color: "#759a58" }}>$STRK</Button>
            </HStack>
          </VStack>
        </VStack>
      </Box>
    </Box>
  );
};
export default Home;
