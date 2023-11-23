const Order = require("./Order");

function AssetType(assetClass, data) {
	return { assetClass, data }
}

function Asset(assetClass, assetData, value) {
	return { assetType: AssetType(assetClass, assetData), value };
}

function Sale(maker, asset, amount, fee, start, end, vaultName, vaultSymbole, salt) {
	return { maker, asset, amount, fee, start, end, vaultName, vaultSymbole, salt }
}


const Types = {
	AssetType: [
		{name: 'assetClass', type: 'bytes4'},
		{name: 'data', type: 'bytes'}
	],
	Asset: [
		{name: 'assetType', type: 'AssetType'},
		{name: 'value', type: 'uint256'}
	],
	Sale: [
		{name: 'maker', type: 'address'},
		{name: 'asset', type: 'Asset'},
		{name: 'amount', type: 'uint256'},
		{name: 'fee', type: 'uint256'},
		{name: 'start', type: 'uint256'},
		{name: 'end', type: 'uint256'},,
		{name: 'vaultName', type: 'string'},
		{name: 'vaultSymbole', type: 'string'},
		{name: 'salt', type: 'uint256'},
	]
};
module.exports = { AssetType, Asset, Sale }