import * as React from "react";
import logo from "../assets/logo.png";
import { backend } from "../../declarations/backend";
import ShowStatus from "./ShowStatus";
import ShowSuccess from "./ShowSuccess";

const App = () => {
  const [isCrowdfundMode, setCrowdfundMode] = React.useState();

  const getResponse = async () => {
    console.log("test");
    const isCrowdfundMode1 = await backend.getCrowdfundStatus();
    setCrowdfundMode(isCrowdfundMode1);
    console.log(isCrowdfundMode);
  };

  React.useEffect(() => {
    getResponse();
  }, []);

  return (
    <main className = "antialiased text-slate-500 dark:text-slate-400 bg-white dark:bg-slate-900 flex justify-center items-center h-screen flex-col">
      <React.Suspense fallback={<h1>Loading...</h1>}>
        {isCrowdfundMode ? (
          <ShowStatus></ShowStatus>
        ) : (
          <ShowSuccess></ShowSuccess>
        )}
      </React.Suspense>
    </main>
  );
};

export default App;
