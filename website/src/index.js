import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import Layout from './components/Layout';
import "@rainbow-me/rainbowkit/styles.css";
import { getDefaultWallets, RainbowKitProvider,darkTheme} from "@rainbow-me/rainbowkit";

import { configureChains, createConfig, WagmiConfig } from 'wagmi';
import { defineChain } from 'viem';
import {
  mainnet,
  polygon,
  optimism,
  arbitrum,
  zora,
  optimismGoerli,
  zoraTestnet,
  sepolia
} from 'wagmi/chains';
import { publicProvider } from 'wagmi/providers/public';

// pages
import Home from './pages/home';
// import Exchange from './pages/exchange.js';
import INO from './pages/INO';
import Detail from './pages/detail';
import CreateNewINO from './pages/CreateNewINO';
import TrackEvents from './pages/TrackEvents';
import Error from './pages/error';
// import Voting from './pages/voting.js';
// import Staking from './pages/staking.js';

import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';

const root = ReactDOM.createRoot(document.getElementById('root'));

export const astria = defineChain({
  id: 69690,
  name: 'astria',
  nativeCurrency: {
    decimals: 18,
    name: 'ASTRIA',
    symbol: 'RIA',
  },
  rpcUrls: {
    default: {
      http: ['http://executor.astria.supervelo.xyz'],
      webSocket: ['wss://executor.astria.supervelo.xyz'],
    },
  },
  blockExplorers: {
    default: { name: 'Explorer', url: 'http://blockscout.astria.supervelo.xyz' },
  },
  // contracts: {
  //   multicall3: {
  //     address: '0xcA11bde05977b3631167028862bE2a173976CA11',
  //     blockCreated: 5882,
  //   },
  // },
})

//WAGMI
const { chains, publicClient } = configureChains(
  [sepolia],
  [
    publicProvider()
  ]
);
const { connectors } = getDefaultWallets({
  appName: 'Tsukuyomi',
  projectId: 'ebbc27c89ea63989fd5cb0ef3d1a49cd',
  chains
});

const wagmiConfig = createConfig({
  autoConnect: true,
  connectors,
  publicClient
})


root.render(
  <WagmiConfig config={wagmiConfig}>
    <RainbowKitProvider chains={chains} theme={darkTheme()}>
      <React.StrictMode>
        <Router>
          <Layout>
            <Routes>
              <Route path="/" element={<Home />}></Route>
              {/* <Route path="/exchange" element={<Exchange />}></Route> */}
              <Route path="/INOs" element={<INO />}></Route>
              <Route path="/LaunchINO" element={<CreateNewINO />}></Route>
              <Route path="/detail/:id" element={<Detail />}></Route>
              {/* <Route path="/voting" element={<Voting />}></Route>
              <Route path="/staking" element={<Staking />}></Route> */}
              <Route path="*" element={<Error code="404" />}></Route>

            </Routes>
          </Layout>
        </Router>
      </React.StrictMode>
    </RainbowKitProvider>
  </WagmiConfig>
);