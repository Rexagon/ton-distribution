const airdrop = require('./../contracts/airdropContract');

const {
  config,
  ton,
  checkContractAddress,
} = require('./utils');


checkContractAddress(config.contractAddress);


(async () => {
  await ton.setup();
  
  const contract = new airdrop(
    ton,
    config.contractAddress,
    config.keys,
  );

  // Contract balance
  const { value0: contract_balance } = await contract.get_current_balanceLocal();
  console.log(`Contract balance: ${parseInt(contract_balance, 16)}`);
  
  
  // Total amount
  const { value0: total_amount } = await contract.get_total_amountLocal();
  console.log(`Total amount: ${parseInt(total_amount, 16)}`);
  
  const balance_status_string = parseInt(contract_balance, 16) > parseInt(total_amount, 16) ? 'Sufficient' : 'Unsufficient';
  
  console.log(`\n${balance_status_string} balance\n`);
  
  // Refund address
  const { value0: refund_address } = await contract.get_refund_destinationLocal();
  console.log(`Refund address: ${refund_address}`);
  
  // Refund lock end
  const { value0: refund_lock_end } = await contract.get_refund_lock_end_timestampLocal();
  const refund_lock_end_date = new Date(parseInt(refund_lock_end, 16) * 1000);
  console.log(`Refund lock ends at: ${refund_lock_end_date}`);
  
  // Get list of receivers, corresponded amounts and distribution status
  const { value0: addresses } = await contract.get_addressesLocal();
  const { value0: amounts } = await contract.get_amountsLocal();

  const distributedStatus = await Promise
    .all([...Array(addresses.length).keys()]
    .map(async (address_index) => {
      const {
        value0: distributed_status
      } = await contract.get_distributed_statusLocal({ i: address_index });
  
      return distributed_status;
    }));
  
  console.log('List of receivers and amounts with distribution status:');
  addresses.map((address, address_index) => {
    console.log(address_index, distributedStatus[address_index], address, parseInt(amounts[address_index], 16));
  });
  
  process.exit(0);
})();
