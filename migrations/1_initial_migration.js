const LowOrbitERC20 = artifacts.require("LowOrbitERC20")
const LowOrbitPropulsor = artifacts.require("LowOrbitPropulsor")

module.exports = async function (deployer, network, accounts) {
  /*
  await deployer.deploy(LowOrbitERC20, { from: accounts[0] })
  const tokenInstance = await LowOrbitERC20.deployed()
  */

  // const tokenInstance = await LowOrbitERC20.at('0x6ef15d1ed7ae15113bed08a548844e0991e62f4f');

  // await deployer.deploy(LowOrbitPropulsor, tokenInstance.address)
  // const propulsorInstance = await LowOrbitPropulsor.deployed()

  // tokenInstance.setStakingContract(propulsorInstance.address)
  // tokenInstance.setExcludedFeesAddr(propulsorInstance.address, true)
  // tokenInstance.setFeesActivated(true)

  // Activate fees and add the staking contract to the excluded fees list
  //const tokenInstance = await LowOrbitERC20.at('0x6ef15d1ed7ae15113bed08a548844e0991e62f4f');
  const propulsorInstance = await LowOrbitPropulsor.at('0xb3EA82a250B7E4f11e445246deF72678114db452');
  await propulsorInstance.setBlocksBetweenPropulsion(15);
  //await tokenInstance.setStakingContract(propulsorInstance.address);
  //await tokenInstance.setExcludedFeesAddr(propulsorInstance.address, true);
  // await tokenInstance.setFeesActivated(true);


  // Don't forget to whitelist the uniswap pool and the router
  /*
  tokenInstance = await LowOrbitERC20.at('0x6ef15d1ed7ae15113bed08a548844e0991e62f4f');
  await tokenInstance.setExcludedFeesAddr("0x98dd9936feb36e9064483082ce1cefab9eb29565", true);
  await tokenInstance.setExcludedFeesAddr("0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", true);
  */

  // Test approve and stake
  /*
  const tokenInstance = await LowOrbitERC20.at('0x6ef15d1ed7ae15113bed08a548844e0991e62f4f');
  const propulsorInstance = await LowOrbitPropulsor.at('0x4Ba8a3109C1729D9b5E57Ba940F76C0BFb649cb6');
  await tokenInstance.approve("0x4Ba8a3109C1729D9b5E57Ba940F76C0BFb649cb6", "1000000000000000000");
  await propulsorInstance.deposit("1000000000000000000");
  */
}
