const LowOrbitERC20 = artifacts.require("LowOrbitERC20")
const LowOrbitPropulsor = artifacts.require("LowOrbitPropulsor")

const truffleAssert = require("truffle-assertions")
const { advanceBlock } = require("./utils")

const BLOCKS_BETWEEN_PROPULSION = 30

contract("LowOrbitPropulsor", async (accounts) => {
  let tokenInstance
  let propulsorInstance

  before(async () => {
    tokenInstance = await LowOrbitERC20.deployed()
    propulsorInstance = await LowOrbitPropulsor.deployed()

    await propulsorInstance.setBlocksBetweenPropulsion(BLOCKS_BETWEEN_PROPULSION)

    const minStakingToBePropelled = web3.utils.toWei("1", "ether")
    await propulsorInstance.setMinStakingToBePropelled(minStakingToBePropelled)

    // const adminBalance = await tokenInstance.balanceOf(accounts[0])

    const transferAmount = web3.utils.toWei("10", "ether")
    await truffleAssert.passes(tokenInstance.transfer(accounts[1], transferAmount, { from: accounts[0] }), "transfer failed")

    const approveAmount = web3.utils.toWei("100", "ether")
    await tokenInstance.approve(propulsorInstance.address, approveAmount, {
      from: accounts[1],
    })
  })

  /*
  it("random test", async () => {
    for (let i = 0; i < 100; i++) {
      const rand = await propulsorInstance.rnd(100)
      console.info("  >", rand.toNumber())
      advanceBlock();
    }
  })
  */

  it("deposit less than minimum", async () => {
    const depositAmount = web3.utils.toWei("0.99", "ether")
    await truffleAssert.reverts(
      propulsorInstance.deposit(depositAmount, {
        from: accounts[1],
      }),
      "Insufficient amount"
    )
  })

  it("deposit", async () => {
    const depositAmount = web3.utils.toWei("1", "ether")
    await truffleAssert.passes(
      propulsorInstance.deposit(depositAmount, {
        from: accounts[1],
      }),
      "deposit failed"
    )
  })

  it("withdraw", async () => {
    const depositAmount = web3.utils.toWei("1", "ether")
    const stakerData = await propulsorInstance.getStakerDataByAddr(accounts[1])
    assert.equal(stakerData.balance, depositAmount)

    await truffleAssert.passes(
      propulsorInstance.withdraw({
        from: accounts[1],
      }),
      "withdraw failed"
    )
  })

  it("make it pulse", async () => {
    const depositAmount = web3.utils.toWei("1", "ether")
    await truffleAssert.passes(
      propulsorInstance.deposit(depositAmount, {
        from: accounts[1],
      }),
      "deposit failed"
    )

    const firstTransferAmount = web3.utils.toWei("5", "ether")
    await truffleAssert.passes(tokenInstance.transfer(accounts[1], firstTransferAmount, { from: accounts[0] }), "first transfer failed")

    const fuelToWinBeforePropulsion = await propulsorInstance.getFuelToWin()
    assert(fuelToWinBeforePropulsion > 0)

    for (let i = 0; i < BLOCKS_BETWEEN_PROPULSION; i++) {
      await advanceBlock()
    }

    const firstAccountBalanceBeforePropulsion = await tokenInstance.balanceOf(accounts[1]);

    const secondTransferAmount = web3.utils.toWei("1", "ether")
    const secondTransferTx = await tokenInstance.transfer(accounts[2], secondTransferAmount, { from: accounts[0] })
    await truffleAssert.passes(secondTransferTx, "second transfer failed")

    const fuelToWinAfterPropulsion = await propulsorInstance.getFuelToWin()
    assert.equal(fuelToWinAfterPropulsion, 0)

    const firstAccountBalanceAfterPropulsion = await tokenInstance.balanceOf(accounts[1]);
    assert(firstAccountBalanceAfterPropulsion > firstAccountBalanceBeforePropulsion);
  })
})
