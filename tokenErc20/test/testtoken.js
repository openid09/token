const MyToken = artifacts.require("MyToken")

contract('[Test MyToken]', async (accounts) => {
    let instance

    beforeEach('Setup contract', async () => {
        instance = await MyToken.new(
            "My Custom Token",
            "MTX",
            18,
            10000
        )
    })

    it("Get totalSupply token", async () => {
        let supply = await instance.totalSupply.call()
        assert.equal(supply, 10000e+18, "The totalSupply doesn't match")
    })

    it("Deploy Token in the first account", async () => {
        let balance = await instance.balanceOf.call(accounts[0])
        assert.equal(balance.valueOf(), 10000e+18, "1 MTX Token isn't in the first account")
    })

    it("Transfer token to second account", async() => {
        // Enable Transfer
        await instance.suspend(false)

        await instance.transfer(accounts[1], 100e+18)

        let balance = await instance.balanceOf.call(accounts[1])
        assert.equal(balance.valueOf(), 100e+18, "100 MTX Token isn't in the second account")
    })

    it("Minting 100 Token to first account", async() => {
        await instance.mint(accounts[0], 100e+18)

        let balance = await instance.balanceOf.call(accounts[0])
        assert.equal(balance.valueOf(), 10100e+18, "10100 MTX Token isn't in the first account")
    })

    it("Burning 10000 MTX Token to first account", async() => {
        await instance.burn(accounts[0], 10000e+18)

        let balance = await instance.balanceOf.call(accounts[0])
        assert.equal(balance.valueOf(), 0, "The MTX Token still exists in first account")
    })

    it("Distribute 100 MTX Token to second account when disabled the transfer", async() => {
        await instance.distribute(accounts[1], 100e+18)

        let balance = await instance.balanceOf.call(accounts[1])
        assert.equal(balance.valueOf(), 100e+18, "100 MTX Token isn't in the second account")
    })

    it("Second account transfer lock and unlock", async() => {
        await instance.suspend(false)
        await instance.transfer(accounts[1], 1000e+18)

        await instance.lock(accounts[1])

        let result = await instance.isLock(accounts[1])
        assert.equal(result, true, "Second account isn't locked")

        let err;
        try {
            await instance.transfer(accounts[2], 100e+18, {from: accounts[1]})
        } catch (e) {
            err = e
        }

        assert.ok(err instanceof Error)

        let balance = await instance.balanceOf.call(accounts[2])
        assert.equal(balance.valueOf(), 0, "Initial balance should be null.")

        await instance.unlock(accounts[1])
        
        await instance.transfer(accounts[2], 100e+18, {from: accounts[1]})
        balance = await instance.balanceOf.call(accounts[2])

        assert.equal(balance.valueOf(), 100e+18, "Balance in second account is 100 MTX.")
    })
})
