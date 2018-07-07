var MyToken = artifacts.require("MyToken");

module.exports = function(deployer, network, accounts) {
    deployer.deploy(MyToken, "My Custom Token", "MTX", 18, 64000000000);
}
