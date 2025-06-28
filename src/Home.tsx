import { Box, Container } from "@chakra-ui/react";
import { useEffect, useRef } from "react";
import * as THREE from "three";
import * as CANNON from "cannon-es";
import Controls from "./components/Controls";

const TAILS = [
  {
    force: 2.7,
    angularVelocity: [10, 4, 0],
  },
  {
    force: 2.9,
    angularVelocity: [10, 4, 0],
  },
  {
    force: 3.1,
    angularVelocity: [10, 4, 0],
  },
  {
    force: 3.2,
    angularVelocity: [10, 4, 0],
  },
  {
    force: 3,
    angularVelocity: [8, 5, 0],
  },
];

const HEADS = [
  {
    force: 3,
    angularVelocity: [10, 2, 0],
  },
  {
    force: 3,
    angularVelocity: [10, 4, 0],
  },
  {
    force: 3,
    angularVelocity: [10, 6, 0],
  },
  {
    force: 4,
    angularVelocity: [9, 3, 0],
  },
  {
    force: 3.8,
    angularVelocity: [9, 5, 0],
  },
];

const Home = () => {
  const mountRef = useRef<HTMLDivElement>(null);
  const flipCoinRef = useRef<((isHeads: boolean) => void) | null>(null);
  const resetCoinRef = useRef<(() => void) | null>(null);
  const isWobblingRef = useRef(false);

  const toggleWobble = (wobble: boolean) => {
    isWobblingRef.current = wobble;
  };

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
    headsTexture.generateMipmaps = false;
    tailsTexture.generateMipmaps = false;

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

    // Coin flip function that can be called from anywhere
    const flipCoin = (isHeads: boolean) => {
      console.log({ isHeads });
      // Select appropriate array based on desired result
      const variants = isHeads ? HEADS : TAILS;

      // Randomly select a variant from the array
      const selectedVariant =
        variants[Math.floor(Math.random() * variants.length)];

      // Reset position and velocity
      coinBody.position.set(0, 0.4, 0);
      coinBody.velocity.set(0, 0, 0);
      coinBody.quaternion.set(0, 0, 0, 1);
      coinBody.angularVelocity.set(
        selectedVariant.angularVelocity[0],
        selectedVariant.angularVelocity[1],
        selectedVariant.angularVelocity[2],
      );

      // Apply upward force
      coinBody.velocity.set(0, selectedVariant.force, 0);
    };

    // Reset coin function to reset position back to initial state
    const resetCoin = () => {
      // Reset position and velocity to initial state
      coinBody.position.set(0, 0.5, 0);
      coinBody.velocity.set(0, 0, 0);
      coinBody.quaternion.set(0, 0, 0, 1);
      coinBody.angularVelocity.set(0, 0, 0);
    };

    // Store functions in refs so they can be accessed outside useEffect
    flipCoinRef.current = flipCoin;
    resetCoinRef.current = resetCoin;

    const handleResize = () => {
      camera.aspect = window.innerWidth / window.innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(window.innerWidth, window.innerHeight);
    };

    window.addEventListener("resize", handleResize);

    const clock = new THREE.Clock();
    const animate = () => {
      requestAnimationFrame(animate);

      const elapsedTime = clock.getElapsedTime();

      // Use fixed timestep for deterministic physics
      const fixedTimeStep = 1 / 60;

      // Step the physics world
      world.step(fixedTimeStep);

      // Always update coin position from physics body
      coin.position.copy(coinBody.position as any);
      coinOutline.position.copy(coin.position);

      if (isWobblingRef.current) {
        // Apply wobble effect if wobbling is enabled
        const wobbleSpeed = 30;
        const wobbleAmount = 0.15;

        coin.rotation.z = Math.sin(elapsedTime * wobbleSpeed) * wobbleAmount;

        coinOutline.rotation.copy(coin.rotation);
      } else {
        // Update coin rotation from physics
        coin.quaternion.copy(coinBody.quaternion as any);
        coinOutline.quaternion.copy(coin.quaternion);
      }

      renderer.render(scene, camera);
    };

    animate();

    // Cleanup
    return () => {
      window.removeEventListener("resize", handleResize);
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
      <Controls
        flip={(isHeads) => flipCoinRef.current?.(isHeads)}
        toggleWobble={toggleWobble}
        reset={() => resetCoinRef.current?.()}
      />
    </Container>
  );
};

export default Home;
