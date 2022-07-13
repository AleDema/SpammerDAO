import React from "react";
import { backend } from "../../declarations/backend";
import {
  toHexString,
  hexToBytes,
  principalToAccountDefaultIdentifier,
} from "./utils.js";

export default function ShowStatus() {
  const [timeLeft, setTimeLeft] = React.useState();
  const [moneyRaised, setMoneyRaised] = React.useState();
  const [deposit, setDeposit] = React.useState();

  const getResponse = async () => {
    const data = await backend.getCrowdfundData();
    // setTimeLeft(data.timeLeft);
    // setMoneyRaised(data.balance);
    setDeposit(toHexString(data.deposit));
    console.log(data.balance);
    console.log(toHexString(data.deposit));
    console.log(data.deposit);
  };

  React.useEffect(() => {
    getResponse();
  }, []);


  const processDeposit = ()=> {

  }

  return (
    <>
      {/* <div>{timeLeft}</div> */}
      <div className = "text-green-500 font-sans">Money raised: {moneyRaised}</div>
      <div className = "text-green-500 font-sans">Deposit address: {deposit}</div>
      <button className="rounded-md bg-gradient-to-r from-green-400 to-blue-500 hover:from-pink-500 hover:to-yellow-500" onClick={processDeposit}>Deposit</button>
    </>
  );
}
