import Typed from 'react-typed';
import { useEffect, useState } from 'react';
import Card from './Card';
import contractAddresses from '../utils/addresses.json';
import mainContractAbi from '../utils/MainAbi.json';
import { writeContract } from '@wagmi/core'

import l1Abi from '../utils/L1Abi.json';
import moment from 'moment';

import { decodeAbiParameters, formatEther } from 'viem';
import { IDKitWidget } from '@worldcoin/idkit';
import { publicClientL1 } from '../utils/viemClients';
import { SnackbarProvider, enqueueSnackbar } from 'notistack';

import { formatUnits } from 'viem';
import { useContractRead } from 'wagmi';
import inoTypes from '../utils/inoTypes';
import { useNavigate } from 'react-router-dom';

import { useParams } from 'react-router-dom';
import { useAccount } from 'wagmi';


const Home = () => {

  const { id } = useParams();
  const { address } = useAccount();

  const [image, setImage] = useState();
  const [shouldGetImage, setGetImage] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [showProofModal, setShowProofModal] = useState(false);





  const contractRead = useContractRead({
    address: contractAddresses.Main,
    abi: mainContractAbi,
    functionName: 'fetchMarketplace',
    args: [id],
    watch: true,
  })

  const isParticipatedRequest = useContractRead({
    address: contractAddresses.Main,
    abi: mainContractAbi,
    functionName: 'participants',
    args: [id, address],
    watch: true,
  })

  const giveawayResultRequest = useContractRead({
    address: contractAddresses.Main,
    abi: mainContractAbi,
    functionName: 'getGiveawayResult',
    args: [id, address],
    watch: true,
  })

  const fetchNFTsOfMarketplaceRequest = useContractRead({
    address: contractAddresses.Main,
    abi: mainContractAbi,
    functionName: 'fetchNFTsOfMarketplace',
    args: [id],
    watch: true,
  })


  const requiredGasRequest = useContractRead({
    address: contractAddresses.Main,
    abi: mainContractAbi,
    functionName: 'getRequiredGasForHyperlane',
  })

  const balanceRequest = useContractRead({
    address: contractAddresses.Main,
    abi: mainContractAbi,
    functionName: 'balance',
    args: [address],
    watch: true,
  })

  const rewardRequest = useContractRead({
    address: contractAddresses.Main,
    abi: mainContractAbi,
    functionName: 'getExecutorReward',
    args: [id],
    watch: true,
  })


  const requiredGas = requiredGasRequest.data;

  const collectionData = contractRead.data;
  console.log("dataTest", collectionData)
  const balance = balanceRequest.data;

  const giveawayResult = giveawayResultRequest.data;

  const NFTs = fetchNFTsOfMarketplaceRequest.data; //kontrattaki nft'leri buna göre yap

  const participantData = isParticipatedRequest?.data;
  const isParticipated = participantData?.[0];
  const participantNonce = participantData?.[1];
  const isClaimed = participantData?.[2];
  const wantedVerification = participantData?.[3];

  console.log("verificatipn", wantedVerification, isParticipated);

  const executorReward = rewardRequest.data;
  console.log("reward", executorReward)
  console.log("execute button test", requiredGas, collectionData?.giveawayTime < moment().unix(), collectionData?.isDistributed)

  //console.log("data", collectionData)



  const isOwner = collectionData?.owner.toLowerCase() === address?.toLowerCase();

  const navigate = useNavigate();

  const navigateDetail = () => {
    navigate('/detail/1')
  }

  const onSuccessWorldId = async (data) => {

    console.log("world data", data);

    const unpackedProof = decodeAbiParameters([{ type: 'uint256[8]' }], data.proof)[0];
    const merkleRoot = decodeAbiParameters([{ type: 'uint256' }], data.merkle_root)[0];
    const nullifierHash = decodeAbiParameters([{ type: 'uint256' }], data.nullifier_hash)[0];


    console.log("args", merkleRoot, nullifierHash, unpackedProof)

    const blockNumber = await publicClientL1.getBlockNumber();
    console.log("block number", blockNumber)


    //contract
    const isContractVerified = await publicClientL1.readContract({
      address: contractAddresses.L1,
      abi: l1Abi,
      functionName: 'verifyWorldIdProof',
      args: [id, address, merkleRoot, nullifierHash, unpackedProof],
    })

    console.log("contract verified", isContractVerified);

    if (isContractVerified) {
      enqueueSnackbar('Correct proof!', { variant: 'success' });
      try {
        const { hash } = await writeContract({
          address: contractAddresses.Main,
          abi: mainContractAbi,
          functionName: 'beParticipant',
          args: [id, merkleRoot, nullifierHash, unpackedProof],
          value: collectionData.price,
        });
        setShowProofModal(true);

      } catch (e) {
        enqueueSnackbar('Person already participated!', { variant: 'error' })
      }

    } else {
      enqueueSnackbar('Proof is wrong!', { variant: 'error' });

    }

  }

  return (
    <>
      <section className="w-full pt-24 md:pt-0 md:h-screen bg-[#02050E] relative flex flex-col md:flex-row justify-center items-center">
        <div className="container mt-10 md:w-1/2 lg:pl-18 xl:pl-24  md:pl-16 flex flex-col md:items-start md:text-left items-center text-center md:ml-24">
          <h1 className="text-4xl mt-10 leading-[44px] md:text-4xl text-white md:leading-tight lg:text-6xl lg:leading-[1.2] font-bold md:tracking-[-2px]">
            Credential rollup that is{' '}
          </h1>
          <Typed
            className="py-3 max-w[200px] text-5xl md:text-6xl bg-clip-text font-extrabold  text-transparent bg-gradient-to-r from-[#7316ff] to-[#f813e1]"
            strings={['fair.', 'decentralized.', 'fast.']}
            typeSpeed={120}
            backSpeed={140}
            loop
          />

          <p className="pt-4 pb-8 md:pt-6 text-gray-400 md:pb-12 max-w-[480px] text-lg text-center lg:text-left">
            You can efficiently verify your users' cross-chain identities by minting Soulbounds 
          </p>

          <button onClick={navigateDetail} className="bg-[#7316ff] mb-5 text-white text-base font-medium px-6 py-3 rounded-lg
          hover:bg-[#7d27ff] hover:scale-[1.03]">
            Mint here!
          </button>
          <IDKitWidget
                  app_id="app_staging_aa5628b6d38113bc3507c644c5bf5630" // must be an app set to on-chain
                  action={"verify_credibilities" + id} // solidityEncode the action
                  signal={address} // only for on-chain use cases, this is used to prevent tampering with a message
                  onSuccess={onSuccessWorldId}
                  // no use for handleVerify, so it is removed
                  credential_types={['orb']} // we recommend only allowing orb verification on-chain
                >
                  {({ open }) =>
                    <button
                      onClick={open}
                      disabled={isParticipated || wantedVerification}
                      className="w-[275px] h-16 p-4 bg-blue-600 rounded-lg justify-center items-start gap-2.5 inline-flex text-white hover:bg-indigo-600 text-lg align-center disabled:bg-gray-600 disabled:text-opacity-60"
                    >
                      <span className=" font-semibold">{wantedVerification ? (isParticipated ? "Already Participated" : "Verifying Proof...") : "WorldId"}</span>
                    </button>
                  }
          </IDKitWidget>
        </div>
        <div className="lg:max-w-lg w-full md:w-1/2 md:mr-28  mb-6 md:mt-20 flex justify-center items-center">
          <div className="w-full md:max-w-[400px] max-w-[100vw] flex justify-center items-center">

            {collectionData && <Card imageUri={collectionData.imageUri} name={collectionData.name} contractAddress={ collectionData.contractAddress} targetTime={collectionData.giveawayTime.toString()} price={formatEther(collectionData.price)} id={1} participant={collectionData.participantNumber.toString()} inoType={inoTypes.Normal}/>}

          </div>
        </div>
      </section>
    </>
  );
}

export default Home;

