import { ethers } from 'ethers';
import { abi } from './stakeAbi.js';
let provider = ethers.getDefaultProvider('ropsten');
let contract = new ethers.Contract('0x9BF0dFC2C453c2bC44Eb1C4aDF4E702a635ff8d0', abi.stakeAbi, provider);
export const stakedTokens = async (address) => {
  try {
    const balanceOf = await contract.balanceOf(address);
    const EtherValue = 10 ** 18;
    return parseInt(balanceOf._hex, 16) / EtherValue;
  } catch (error) {
    console.log(error);
  }
};
export const rewardTokens = async (address) => {
  try {
    const rewards = await contract.rewards(address);
    const EtherValue = 10 ** 18;
    return parseInt(rewards._hex, 16) / EtherValue;
  } catch (error) {
    console.log(error);
  }
};
export const userData = async () => {
  let i = 0;
  let users = [];
  while (true) {
    try {
      const address = await contract.stakedAddresses(i);
      const rewards = await rewardTokens(address);
      const stakedToken = await stakedTokens(address);
      
      let temp = {
        address,
        rewards,
        stakedToken,
      };
      users.push(temp);
      i++;
    } catch (error) {
    //   console.log(error);
      break;
    }
  }
  return users;
};
