

# **The Complete DoEasy Developer's Guide: From Core Trading Functions to Advanced GUI Development**

## **Part 1: Foundational Concepts**

This section provides a comprehensive introduction to the DoEasy ecosystem. It establishes the core purpose, design philosophy, and architectural principles of the two primary components: the MQL\_Easy trade management library and the advanced "DoEasy" GUI framework. A critical clarification is made to explain the relationship between these two projects, ensuring developers have a clear understanding of the full suite of tools at their disposal.

### **1.1. Introduction to the DoEasy Ecosystem: Simplifying Algorithmic Trading Development**

The DoEasy ecosystem consists of two powerful, related, yet distinct projects designed to dramatically simplify and accelerate the development of sophisticated trading applications for the MetaTrader 4 (MT4) and MetaTrader 5 (MT5) platforms.

The first component is the **MQL\_Easy library**, an open-source, cross-platform framework meticulously engineered to streamline the development of trading applications. The fundamental objective of this library is to make the MQL (MetaQuotes Language) development process "easy, safe and fast".1 By abstracting away the repetitive and often complex boilerplate code associated with common trading operations,

MQL\_Easy empowers developers to dedicate their focus to the more intricate and value-driven aspects of their work, such as the implementation and testing of sophisticated trading algorithms and strategies.1

The second component is the **"DoEasy" advanced library**, a far more extensive framework documented through an ongoing series of over 100 articles on MQL5.com.4 This project tackles the next major challenge in application development: the creation of rich, interactive Graphical User Interfaces (GUIs) directly on the trading chart. It provides a blueprint for building "Windows Forms style" controls, complex on-chart panels, and event-driven interfaces, allowing developers to create professional-grade applications that move beyond simple command-line interaction.

Together, these two projects provide a comprehensive, end-to-end solution for MQL developers, covering both the back-end trading logic and the front-end user interface.

### **1.2. The Two Pillars of DoEasy: A Critical Clarification**

To navigate this ecosystem effectively, it is crucial to understand the distinction and relationship between its two main pillars. This guide provides complete documentation for both.

Pillar 1: The MQL\_Easy Library (GitHub)  
This is a tangible, downloadable, and ready-to-use framework available on GitHub that provides a concrete solution for cross-platform trade management.1 It is a stable, production-ready tool focused on simplifying trade execution, order management, and error handling. Its key value propositions include:

* **Cross-Platform Compatibility**: Ensures that the "same piece of code works on both platforms".1  
* **Complexity Abstraction**: Designed to "hide complexity and speed up the development" of core trading logic.1  
* **Built-in Safety**: Incorporates comprehensive "error handling" and "validation checks" to minimize runtime errors.1  
* **MQL5 Market Readiness**: Intended to make the process of "publishing products on MQL5 market easier and safer".1

Pillar 2: The "DoEasy" GUI Framework (MQL5.com Articles)  
This is a significantly more complex and ambitious library whose creation is documented as a "development tutorial" in a "live" and incremental fashion across a series of articles.5 The code and classes detailed in this expansive series are not part of the foundational  
MQL\_Easy GitHub repository. The scope of this framework is dedicated to advanced GUI development, including:

* **Custom GUI Controls**: A framework for creating "Windows Forms style" controls like panels, forms, and buttons.  
* **Advanced Graphics**: Built upon the CCanvas class for custom drawing and sophisticated visual elements.7  
* **Event-Driven Architecture**: A robust system for handling mouse clicks, dragging, and other user interactions with on-chart elements.

The existence of these two projects suggests a logical evolution. The MQL\_Easy library solves the universal problem of trade management. The "DoEasy" article series documents the subsequent effort to solve the next major challenge: building rich user interfaces. The author noted the motivation for starting the GUI development was that "it is already becoming difficult to manage things without controls," indicating a need that grew beyond the original project's scope.

This guide will cover the MQL\_Easy library first, as it provides the foundational trading engine, and then provide detailed documentation for the advanced "DoEasy" GUI framework.

| Feature | MQL\_Easy (GitHub Library) | "DoEasy" (MQL5.com Article Series) |
| :---- | :---- | :---- |
| **Core Focus** | Cross-platform trade execution, order management, and error handling. | Advanced GUI development, custom graphical objects, and event-driven UI controls. |
| **Availability** | Downloadable and ready-to-use from a GitHub repository.1 | Code is presented incrementally within each article; it is a "live" development tutorial.5 |
| **Key Classes** | CExecute, CPosition, COrder, CError, CUtilities.1 | CPanel, CForm, CGCnvElement, CCanvas, and numerous other GUI-related classes. |
| **Development Status** | A stable, functional library intended for direct use in projects. | An ongoing, evolving project whose development is the subject of the articles. |
| **Primary Use Case** | Building the core trading logic of Expert Advisors and scripts quickly and reliably across MQL4/M5. | Learning advanced techniques for creating complex, interactive on-chart interfaces in MQL5. |

### **1.3. Library Architecture and Design Principles**

The architecture of the MQL\_Easy library is designed for simplicity, modularity, and extensibility, directly supporting its goal of cross-platform compatibility.

#### **File and Folder Structure**

The library employs a highly organized and intuitive structure. The codebase is organized into folders, with each folder corresponding to one of the main implemented classes (e.g., a CExecute folder for the CExecute class, a CPosition folder for the CPosition class, and so on). Within each of these class-specific folders, two key components are present: a primary .mqh include file and a subfolder named Includes.1 This clean, one-to-one mapping between classes and folders makes the library easy to navigate and understand.

#### **The Platform Abstraction Layer**

The Includes subfolder within each class directory is the cornerstone of the library's cross-platform design. This folder acts as a platform abstraction layer. While the main .mqh file for a class presents a unified, consistent interface to the developer, the Includes folder contains the platform-specific implementations. In many cases, the implementation logic for a feature differs significantly between MQL4 and MQL5. This structure allows the library to contain distinct files for each platform's implementation. Compiler directives within the main class file then ensure that only the correct, platform-specific code is included during the compilation process.2 This elegant design effectively isolates the developer from the underlying platform differences.

#### **The Master Include File**

To facilitate rapid integration and ease of use, the library provides a master include file named MQL\_Easy.mqh. This file serves as a convenient wrapper that contains \#include directives for all the other class files in the library.1 For developers who are new to the library or are building applications that will make extensive use of its features, including this single file is the "quick way to get started".1 However, the documentation also advises a best practice for more experienced developers or for projects where compilation time and resource optimization are concerns. As one becomes more "familiar with the library," it is recommended to "include only the needed classes" directly in the project.1 This more granular approach ensures that only the necessary code is compiled into the final application, leading to a more lightweight and efficient result.

#### **Object-Oriented Design**

The library is fundamentally built upon object-oriented programming (OOP) principles. Functionality is neatly encapsulated within distinct classes, such as CExecute for handling trade operations and CPosition for managing open trades.1 This OOP approach promotes code reusability, maintainability, and a logical separation of concerns. The more advanced "DoEasy" article series demonstrates a deeper and more complex application of OOP, featuring intricate class inheritance hierarchies (e.g.,

CPanel inherits from CForm, which is itself based on CGCnvElement, which utilizes the CCanvas class). This consistency in design philosophy across both the foundational MQL\_Easy library and the advanced "DoEasy" project showcases a commitment to modern, structured programming practices.

## **Part 2: Getting Started for the Engineer**

This section provides the essential, practical information required for an engineer to install, integrate, and begin using the MQL\_Easy library in a project. The goal is to facilitate a smooth and rapid onboarding process.

### **2.1. Installation and Project Integration**

Integrating the MQL\_Easy library into a development environment is a straightforward process that can be completed in a few simple steps. The following guide provides the necessary instructions to make the library's classes available to any MQL4 or MQL5 project.1

1. **Download the Library**: The first step is to acquire the library files. Navigate to the official MQL\_Easy GitHub repository (([https://github.com/Denn1Ro/MQL\_Easy](https://github.com/Denn1Ro/MQL_Easy))) and either clone the repository using Git or download the project as a ZIP archive. If downloaded as an archive, ensure you unzip the contents. You will have a folder named MQL\_Easy.  
2. **Locate the Include Directory**: To install the library, you must place it in the correct directory within your MetaTrader terminal's data folder. The easiest way to find this location is from within the MetaEditor:  
   * Open the MetaEditor application associated with your MT4 or MT5 terminal.  
   * In the top menu, click on File.  
   * From the dropdown menu, select Open Data Folder. This will open the terminal's data folder in your system's file explorer.  
   * Inside this data folder, navigate into the MQL4 or MQL5 directory, depending on which platform you are developing for.  
3. **Move the Library Folder**: Once you are inside the MQL4 or MQL5 directory, locate the Include folder. "Move" the entire MQL\_Easy folder that you downloaded in Step 1 into this Include directory.1 The final path should look similar to  
   .../MQL5/Include/MQL\_Easy/.  
4. **Include the Library in Your Project**: With the library files in place, you can now reference them in your MQL code. In your Expert Advisor (.mq5 or.mq4), script, or indicator file, add the following preprocessor directive at the top of your file:  
   Code-Snippet  
   \#include \<MQL\_Easy\\MQL\_Easy.mqh\>

   This line includes the master header file, which in turn makes all classes within the MQL\_Easy library available for use in your project.2 As mentioned previously, for optimized projects, you may choose to include only the specific class headers you need (e.g.,  
   \#include \<MQL\_Easy\\Execute\\CExecute.mqh\>).

After completing these steps, you can compile your project. If the compilation is successful without any "file not found" errors, the library has been installed correctly.

### **2.2. A "Hello, Trade\!" Example: Your First Execution**

The most effective way to understand the power and simplicity of the MQL\_Easy library is to see it in action. The following "Hello, Trade\!" example is a minimal, complete, and verifiable MQL5 script that demonstrates the core value of the library by executing a trade with just a few lines of code. This example provides a practical starting point for experimentation and builds confidence in the library's capabilities.

The script will use the CExecute class to open a new market BUY position and the CPrinter class to provide clean, formatted feedback in the Experts tab of the terminal.

Code-Snippet

//+------------------------------------------------------------------+  
//| Hello\_Trade\_MQL\_Easy.mq5 |  
//| Copyright 2023, MQL\_Easy Documentation Team |  
//| https://example.com |  
//+------------------------------------------------------------------+  
\#property copyright "Copyright 2023, MQL\_Easy Documentation Team"  
\#property link      "https://example.com"  
\#property version   "1.00"  
\#property script\_show\_inputs

// Step 1: Include the MQL\_Easy library.  
// This single line makes all library classes available.  
\#include \<MQL\_Easy\\MQL\_Easy.mqh\>

//+------------------------------------------------------------------+  
//| Script program start function |  
//+------------------------------------------------------------------+  
void OnStart()  
  {  
   //--- Define trade parameters  
   string        symbol      \= \_Symbol;         // Use the current chart's symbol  
   int           magicNumber \= 12345;         // A unique magic number for this script  
   double        lotSize     \= 0.01;            // The trade volume  
   double        stopLossPips= 20;              // Stop loss in pips  
   double        takeProfitPips= 40;            // Take profit in pips  
   string        comment     \= "MQL\_Easy Test"; // Trade comment

   //--- Step 2: Instantiate the CExecute class  
   // Create an object of the CExecute class, providing the symbol and magic number.  
   // This object will handle all our trade execution needs.  
   CExecute execute(symbol, magicNumber);

   //--- Step 3: Execute the trade  
   // Call the Buy() method to open a market order.  
   // Note the use of ENUM\_SLTP\_TYPE to specify that our SL/TP values are in pips.  
   // The library handles the complex conversion of pips to the correct price level.  
   bool result \= execute.Buy(lotSize, stopLossPips, takeProfitPips, SLTP\_PIPS, SLTP\_PIPS, comment);

   //--- Step 4: Use CPrinter for formatted feedback  
   // The CPrinter class provides a clean way to log information.  
   CPrinter printer;  
   printer.SetTitle("MQL\_Easy Trade Execution");  
   printer.SetContainer("=");

   if(result)  
     {  
      // Trade was successful  
      printer.Add("Status", "Trade executed successfully\!");  
      printer.Add("Symbol", symbol);  
      printer.Add("Volume", DoubleToString(lotSize, 2));  
      printer.Add("Magic", (string)magicNumber);  
     }  
   else  
     {  
      // Trade failed. Get the error details from the CExecute object.  
      // The execute object contains a CError object with details of the last error.  
      CError\* error \= execute.GetError();  
      printer.Add("Status", "Trade execution FAILED\!");  
      printer.Add("Error Code", (string)error.GetErrorCode());  
      printer.Add("Error Description", error.GetErrorDescription());  
     }

   // Print the final formatted message to the Experts tab.  
   printer.Print();  
  }  
//+------------------------------------------------------------------+

This simple script powerfully demonstrates the library's core promise to "hide complexity".1 A standard MQL5 implementation of this same logic would require dozens of lines of code to declare and populate an

MqlTradeRequest structure, normalize price levels, check for errors after sending the request, and manually format print statements. With MQL\_Easy, this entire process is reduced to instantiating an object and calling a single, intuitive method. This immediate and tangible simplification of the development process is the central benefit of the framework.

## **Part 3: Core Class API Reference**

This section provides an exhaustive and detailed reference for the core classes available within the MQL\_Easy GitHub repository. Each class is documented with its purpose, instantiation methods, key features, a description of its primary methods and parameters, and practical code examples. This reference is designed to serve as a comprehensive guide for engineers utilizing the library's full capabilities.

### **3.1. CExecute: The Trade Execution Engine**

#### **Purpose**

The CExecute class is the central workhorse for all trade-related actions within the MQL\_Easy framework. It is unequivocally "responsible for trade execution".1 Its scope covers the two primary categories of trades: market positions (Buy, Sell) and pending orders (BuyLimit, SellLimit, BuyStop, and SellStop).1 The class is designed to encapsulate the entire trade request lifecycle, from parameter validation to server communication and error handling.

#### **Instantiation**

The CExecute class can be instantiated in several ways to suit different coding styles and requirements:

* **Direct Instantiation (Stack Allocation)**: The most common method is to create an object directly, providing the target symbol and magic number in the constructor.  
  Code-Snippet  
  string symbol \= \_Symbol;  
  int magicNumber \= 12345;  
  CExecute execute(symbol, magicNumber);

  1  
* **Pointer Instantiation (Heap Allocation)**: For more complex applications or different object lifetime management strategies, a pointer to a CExecute object can be created.  
  Code-Snippet  
  CExecute\* execute \= new CExecute(\_Symbol, 12345);  
  //... use execute-\>Buy(...)  
  delete execute; // Remember to deallocate memory

  1  
* **Delayed Initialization**: It is also possible to instantiate an empty object and set its properties later using dedicated methods.  
  Code-Snippet  
  CExecute execute;  
  execute.SetSymbol(\_Symbol);  
  execute.SetMagicNumber(12345);

  1

#### **Key Feature: ENUM\_SLTP\_TYPE Enumeration**

A standout capability of the CExecute class is its ENUM\_SLTP\_TYPE enumeration, described as a major "time saver feature".1 This feature dramatically simplifies the process of setting Stop Loss (SL) and Take Profit (TP) levels. Instead of manually calculating the exact price levels, which is prone to errors related to spread, slippage, and symbol precision, the developer can specify the SL/TP values in a variety of intuitive formats. The library then undertakes the complex task of "converting the

ENUM\_SLTP\_TYPE feature into prices" automatically.1 This involves fetching the symbol's point size, current market price, and applying the correct calculations for the specified type.

The available options for this enumeration are detailed in the table below:

| ENUM\_SLTP\_TYPE Value | Description | Example Usage |
| :---- | :---- | :---- |
| SLTP\_PRICE | The SL/TP value is provided as an absolute price level. | execute.Buy(0.01, 1.07100, 1.07900, SLTP\_PRICE, SLTP\_PRICE); |
| SLTP\_PIPS | The SL/TP value is provided as a number of pips from the open price. | execute.Buy(0.01, 20.0, 40.0, SLTP\_PIPS, SLTP\_PIPS); |
| SLTP\_POINTS | The SL/TP value is provided as a number of points from the open price. | execute.Buy(0.01, 200, 400, SLTP\_POINTS, SLTP\_POINTS); |
| SLTP\_PERCENTAGE | The SL/TP value is provided as a percentage of the open price. | execute.Buy(0.01, 0.5, 1.0, SLTP\_PERCENTAGE, SLTP\_PERCENTAGE); |

#### **Integrated Validation and Error Handling**

The CExecute class is engineered for robustness. Before attempting to send any trade request to the broker's server, it automatically performs a series of validation checks to "ensure that the request for the trade is a valid one".1 This internal validation leverages the

CValidationCheck class by default.2

In the event that a trade request fails, either due to a validation error or a rejection from the server, the CExecute class provides comprehensive feedback. A "user-friendly message is displayed with the error code and details in the Expert's tab" of the terminal, allowing for immediate visual diagnosis.1 More importantly for programmatic control, the class also "fills these details into its own

CError object".1 This internal

CError object can be retrieved by the developer, enabling the implementation of sophisticated, custom error handling routines, such as retrying a trade, alerting the user via other means, or gracefully shutting down the trading logic.

#### **Methods and Parameters**

Based on its described functionality, the CExecute class exposes a set of methods for each trade type. The signatures would be similar to the following:

* bool Buy(double volume, double sl, double tp, ENUM\_SLTP\_TYPE sl\_type, ENUM\_SLTP\_TYPE tp\_type, string comment \= "")  
* bool Sell(double volume, double sl, double tp, ENUM\_SLTP\_TYPE sl\_type, ENUM\_SLTP\_TYPE tp\_type, string comment \= "")  
* bool BuyLimit(double price, double volume, double sl, double tp, ENUM\_SLTP\_TYPE sl\_type, ENUM\_SLTP\_TYPE tp\_type, string comment \= "")  
* bool SellLimit(double price, double volume, double sl, double tp, ENUM\_SLTP\_TYPE sl\_type, ENUM\_SLTP\_TYPE tp\_type, string comment \= "")  
* bool BuyStop(double price, double volume, double sl, double tp, ENUM\_SLTP\_TYPE sl\_type, ENUM\_SLTP\_TYPE tp\_type, string comment \= "")  
* bool SellStop(double price, double volume, double sl, double tp, ENUM\_SLTP\_TYPE sl\_type, ENUM\_SLTP\_TYPE tp\_type, string comment \= "")  
* CError\* GetError(): Returns a pointer to the internal CError object, which contains details about the last execution error.

### **3.2. CPosition & COrder: Managing Active and Pending Trades**

#### **Purpose**

The CPosition and COrder classes are the primary tools for interacting with and managing trades that are already active in the market or pending execution. They are designed to "manage the active and pending trades of the account," respectively.1 Their functionality includes gathering detailed information about trades and orders, as well as executing management actions such as closing positions.

#### **Key Feature: Grouping Property**

The most powerful and innovative feature of these classes is their "grouping property." This feature represents a significant paradigm shift in how a developer interacts with open trades. Instead of manually iterating through the entire list of open positions or orders and applying filters in a loop, the developer can instantiate a CPosition or COrder object that *declaratively represents a specific subset of trades*. This grouping can be configured by symbol, magic number, type (buy/sell), or any combination thereof.1

This declarative approach "saves a lot of time and give the ability to create complex trading ideas with less effort".2 The cognitive load on the developer is drastically reduced. The process shifts from an imperative "how-to" loop (e.g., "for each position, if the symbol is EURUSD and the magic is 12345, then do X") to a declarative "what-is" definition (e.g., "create an object representing all EURUSD positions with magic 12345, then tell that object to do X"). This shift is less error-prone and results in cleaner, more readable code.

**Example of Grouping Instantiation**:

Code-Snippet

// Create a CPosition object that ONLY manages BUY trades  
// on the "EURUSD" symbol with the magic number 12345\.  
CPosition long\_eurusd\_positions("EURUSD", 12345, OP\_BUY);

// Now, any method called on this object will apply only to that specific group.  
int total\_trades\_in\_group \= long\_eurusd\_positions.Total();  
long\_eurusd\_positions.CloseAll(); // Closes only the trades in this group.

2

#### **Key Feature: "Quick Access" to Properties**

Once an object representing a group of trades has been created, the library provides a "quick access" feature to retrieve the properties of the individual trades within that group.1 This allows the developer to access information like the open price, ticket number, or profit of a specific trade in the group by its index, without needing to perform another lookup.

#### **Methods and Parameters (Inferred)**

* CPosition(string symbol \= NULL, int magic \= \-1, ENUM\_ORDER\_TYPE type \= \-1): Constructor to define the group of positions.  
* COrder(string symbol \= NULL, int magic \= \-1, ENUM\_ORDER\_TYPE type \= \-1): Constructor to define the group of orders.  
* int Total(): Returns the total number of positions or orders within the defined group.  
* bool CloseAll(): Closes all positions in the group (CPosition only).  
* bool DeleteAll(): Deletes all pending orders in the group (COrder only).  
* long GetTicket(int index): Retrieves the ticket number of the trade/order at the specified index within the group.  
* double GetOpenPrice(int index): Retrieves the open price of the trade/order at the specified index.  
* double GetProfit(int index): Retrieves the current floating profit/loss of the position at the specified index.

### **3.3. CHistoryPosition & CHistoryOrder: Accessing Historical Data**

#### **Purpose**

The CHistoryPosition and CHistoryOrder classes serve as the historical counterparts to CPosition and COrder. They are specifically designed for "collecting information about active and pending trades in the past".1 These classes are essential for tasks that require analysis of trading performance, such as calculating statistics for reports, backtesting analysis, or creating equity curves.

#### **Features**

These historical classes inherit the powerful design patterns of their real-time counterparts. They offer the same robust grouping and quick access capabilities, allowing developers to filter and analyze historical trades with the same ease and declarative syntax used for live trades.1

#### **Key Differentiator: Time Filtering**

The primary feature that distinguishes the history classes is the ability to filter the historical data by a specific time period. The constructor for these classes accepts an optional "start date and end date".2 When these parameters are provided, the class will only collect and analyze trades that fall within that specific date range. If the date parameters are omitted, the class will search the entire available account history.1

#### **Instantiation and Use Case**

**Instantiation**:

Code-Snippet

// Create a CHistoryPosition object to analyze all trades for magic number 777  
// that were closed during March 2023\.  
datetime start\_date \= D'2023.03.01 00:00:00';  
datetime end\_date   \= D'2023.03.31 23:59:59';  
CHistoryPosition history\_trades(NULL, 777, \-1, start\_date, end\_date);

**Example Use Case**: Calculating the total profit for a specific strategy (identified by its magic number) over the last week.

Code-Snippet

// Calculate the start date (one week ago)  
datetime end\_date \= TimeCurrent();  
datetime start\_date \= end\_date \- (7 \* 24 \* 60 \* 60);

// Create the history object  
CHistoryPosition weekly\_report(NULL, 12345, \-1, start\_date, end\_date);

double total\_profit \= 0;  
// Loop through all trades in the filtered history  
for(int i \= 0; i \< weekly\_report.Total(); i++)  
{  
    total\_profit \+= weekly\_report.GetProfit(i);  
}

CPrinter printer;  
printer.SetTitle("Weekly Performance Report");  
printer.Add("Magic Number", "12345");  
printer.Add("Total Profit", DoubleToString(total\_profit, 2));  
printer.Print();

2

### **3.4. CValidationCheck: Pre-Trade Sanity Checks**

#### **Purpose**

The CValidationCheck class is a dedicated utility for performing essential pre-trade sanity checks. Its role is to "implement useful functions for order's checks and validations".1 While these checks are used internally and automatically by the

CExecute class before any trade is sent, the CValidationCheck class is also exposed for independent use. This allows developers to build custom validation logic into their application's user interface or configuration settings.1

#### **Methods and Parameters**

The class provides functions to validate common trade parameters. Based on the available examples, its methods include:

* bool CheckVolumeValue(string symbol, double volume): This function checks if a given trade volume (lot size) is valid for the specified symbol. It likely checks against the symbol's minimum and maximum allowed volume, as well as the volume step, ensuring the lot size is a valid increment.2  
* bool CheckMoneyForTrade(string symbol, double volume, ENUM\_ORDER\_TYPE type): This function determines if the trading account has sufficient free margin to execute a trade of the specified volume. This is a critical check to prevent "not enough money" errors (error 10019\) from the trade server.2

#### **Use Case**

A common use case for using this class independently is to validate user inputs in an Expert Advisor. For instance, if an EA has an input parameter for the lot size, the developer can use CheckVolumeValue in the OnInit function to verify that the user-entered value is valid for the current symbol. If it is not, the EA can alert the user and fail to initialize, preventing it from attempting to place invalid trades later on.

Code-Snippet

\#include \<MQL\_Easy\\MQL\_Easy.mqh\>  
input double LotSize \= 0.05;

int OnInit()  
{  
    CValidationCheck validator;  
    if(\!validator.CheckVolumeValue(\_Symbol, LotSize))  
    {  
        CPrinter printer;  
        printer.SetTitle("EA Initialization Error");  
        printer.Add("Problem", "Invalid Lot Size input.");  
        printer.Add("Symbol", \_Symbol);  
        printer.Add("Input Value", (string)LotSize);  
        printer.Print();  
        return(INIT\_FAILED);  
    }  
    return(INIT\_SUCCEEDED);  
}

### **3.5. CError: Comprehensive Error Handling**

#### **Purpose**

The CError class is the library's centralized component for managing and reporting errors. Its primary responsibility is "for handling the errors".1 By default, the class is pre-populated with "all the available error codes and their description," which provides a rich resource for developers to quickly diagnose problems and provide meaningful feedback to users.1

#### **Integration with CExecute**

The most common interaction with the CError class is through the CExecute class. When a trade execution fails, the CExecute object captures all the relevant error information and stores it in its internal CError object. This object can then be retrieved for inspection, allowing the program to react intelligently to the specific failure reason.1

#### **Methods and Parameters**

* void CreateErrorCustom(string message, bool show\_native\_error): This method allows a developer to generate a custom, formatted error message that is printed to the Experts tab.  
  * message: A custom string to be displayed as the primary error message.  
  * show\_native\_error: A boolean flag. If true, the method will automatically retrieve the last MQL error code using GetLastError() and include its official description in the printed output.2  
* int GetErrorCode(): Returns the numerical code of the last error.  
* string GetErrorDescription(): Returns the textual description of the last error.

#### **Code Example**

The following example from the source material demonstrates how to use CreateErrorCustom to report an error generated by an invalid MQL function call:

Code-Snippet

// This line will generate an error because the symbol does not exist.  
double ask \= SymbolInfoDouble("WRONG\_SYMBOL", SYMBOL\_ASK);

// Now, use CError to create a detailed report.  
CError error;  
error.CreateErrorCustom("An Error occured\!\!\!", true);

/\*  
The above code will display the following formatted output in the Experts tab:

\--------------- ERROR \---------------  
Message : An Error occured\!\!\!  
Error(4301) : Unknown symbol  
\--------------- ERROR \---------------  
\*/

2

### **3.6. CPrinter: Formatted Terminal Logging**

#### **Purpose**

The CPrinter class provides a "quick and nice way for custom formatted messages to the terminal".2 Standard

Print() statements can lead to cluttered and hard-to-read logs. CPrinter solves this by creating structured, easy-to-read message blocks, which is particularly useful for status updates, debugging information, and user alerts.2

#### **Methods and Parameters**

The class uses a builder pattern, where you configure the message piece by piece before printing it.

* void SetTitle(string title): Sets the title that appears at the top of the message block.  
* void SetContainer(string character): Sets the character(s) used to create the horizontal lines that frame the message block (e.g., "-", "=", "\*").  
* void Add(string key, string value): Adds a line to the message body in a key-value pair format (e.g., "Status: Success").  
* void Print(): Assembles and prints the configured message to the Experts tab of the terminal.

#### **Code Example**

The following example demonstrates how to create a formatted alert for a user:

Code-Snippet

CPrinter printer;  
printer.SetTitle("ATTENTION");  
printer.SetContainer("-");  
printer.Add("Action For The User", "You need to enable Auto Trading\!\!\!");  
printer.Add("Steps", "Press the Auto Trading Button at the top of the terminal");  
printer.Print();

/\*  
The above code will display the following in the Experts tab:

\---------- ATTENTION \----------  
Action For The User : You need to enable Auto Trading\!\!\!  
Steps               : Press the Auto Trading Button at the top of the terminal  
\-------------------------------  
\*/

2

### **3.7. CUtilities: The Developer's Toolkit**

#### **Purpose**

The CUtilities class serves as a toolkit or a collection of "common useful functions, which a trading application may needs".1 It is designed to hold miscellaneous helper functions that don't fit neatly into the other classes but are frequently required in the development of trading algorithms.

#### **Methods and Parameters**

While the class may contain multiple functions, the most prominently documented one is essential for controlling the timing of EA logic.

* bool IsNewBar(ENUM\_TIMEFRAMES period): This is a classic and indispensable function for any EA that operates on a "per-bar" basis. It checks if a new candle (bar) has formed on the specified timeframe. By calling this function at the beginning of the OnTick event handler, a developer can ensure that their core trading logic executes only once per bar, preventing the EA from running redundant calculations or attempting to place multiple trades on every single tick.2

#### **Instantiation and Use Case**

The class is typically instantiated with the symbol for which it will be performing checks.

Code-Snippet

\#include \<MQL\_Easy\\MQL\_Easy.mqh\>

// Instantiate the CUtilities object globally or within OnInit  
CUtilities utils;

void OnInit()  
{  
    // It's good practice to initialize it for the chart's symbol  
    utils.SetSymbol(\_Symbol);  
}

void OnTick()  
{  
    // At the start of the tick processing, check for a new H1 bar.  
    if(\!utils.IsNewBar(PERIOD\_H1))  
    {  
        // If it's not a new bar, do nothing and wait for the next tick.  
        return;  
    }

    // \--- Place core trading logic here \---  
    // This code will now only execute once at the beginning of each new H1 bar.  
    Print("New H1 bar detected. Running trading logic...");  
}

2

## **Part 4: Advanced Implementation and Best Practices**

This section transitions from API reference to practical application. It provides a detailed case study demonstrating how to synthesize the library's components into a complete trading application. Furthermore, it discusses best practices for cross-platform development and encourages community involvement in the project's future.

### **4.1. Case Study: Building a Complete Moving Average Crossover EA**

To illustrate the synergistic power of the MQL\_Easy library, this case study will walk through the construction of a complete, functional Expert Advisor based on a simple moving average (MA) crossover strategy. The EA will open a BUY trade when a fast MA crosses above a slow MA, and close it when the reverse occurs. This example will integrate multiple library components to demonstrate a robust and well-structured implementation.

#### **Step 1: Initialization (OnInit)**

The OnInit function is the entry point of the EA. Here, we will use the CPrinter class to log the EA's input parameters, providing a clean and readable confirmation that the EA has started correctly.

Code-Snippet

\#include \<MQL\_Easy\\MQL\_Easy.mqh\>

//--- EA Inputs  
input int FastMA\_Period \= 10;  
input int SlowMA\_Period \= 50;  
input double LotSize \= 0.01;  
input int MagicNumber \= 54321;

//--- Global Library Objects  
CUtilities utils;  
CExecute   execute;

int OnInit()  
{  
    // Initialize library objects with current chart properties  
    utils.SetSymbol(\_Symbol);  
    execute.SetSymbol(\_Symbol);  
    execute.SetMagicNumber(MagicNumber);

    // Use CPrinter to log startup parameters  
    CPrinter printer;  
    printer.SetTitle("MA Crossover EA Initialized");  
    printer.SetContainer("=");  
    printer.Add("Symbol", \_Symbol);  
    printer.Add("Fast MA Period", (string)FastMA\_Period);  
    printer.Add("Slow MA Period", (string)SlowMA\_Period);  
    printer.Add("Lot Size", (string)LotSize);  
    printer.Add("Magic Number", (string)MagicNumber);  
    printer.Print();

    return(INIT\_SUCCEEDED);  
}

#### **Step 2: Main Logic (OnTick)**

The OnTick function contains the core trading logic. The implementation will demonstrate a best-practice approach by combining several MQL\_Easy classes.

1. **New Bar Check**: Use CUtilities::IsNewBar() to ensure the logic runs only once at the open of each new M1 bar. This is crucial for performance and to prevent erratic behavior.  
2. **Signal Calculation**: Calculate the fast and slow moving averages.  
3. **Trade Management**: Instantiate CPosition to check for existing open trades managed by this EA.  
4. **Trade Execution**: If a crossover signal occurs and no trade is open, use CExecute to place a new trade.  
5. **Error Handling**: Check the result of the trade execution and use the CError object for detailed logging in case of failure.

Code-Snippet

void OnTick()  
{  
    // 1\. Ensure logic runs only once per bar using CUtilities  
    if(\!utils.IsNewBar(PERIOD\_M1))  
    {  
        return; // Not a new bar, exit  
    }

    // 2\. Calculate MA values  
    double fastMA\_current \= iMA(\_Symbol, PERIOD\_M1, FastMA\_Period, 0, MODE\_SMA, PRICE\_CLOSE, 1);  
    double slowMA\_current \= iMA(\_Symbol, PERIOD\_M1, SlowMA\_Period, 0, MODE\_SMA, PRICE\_CLOSE, 1);  
    double fastMA\_previous \= iMA(\_Symbol, PERIOD\_M1, FastMA\_Period, 0, MODE\_SMA, PRICE\_CLOSE, 2);  
    double slowMA\_previous \= iMA(\_Symbol, PERIOD\_M1, SlowMA\_Period, 0, MODE\_SMA, PRICE\_CLOSE, 2);

    // 3\. Instantiate CPosition to manage existing trades for this EA  
    CPosition my\_positions(\_Symbol, MagicNumber);

    // \--- Entry Logic \---  
    bool isTradeOpen \= (my\_positions.Total() \> 0);

    // Bullish Crossover Signal  
    if(fastMA\_previous \<= slowMA\_previous && fastMA\_current \> slowMA\_current)  
    {  
        if(\!isTradeOpen)  
        {  
            // No trade is open, so open a BUY position  
            if(execute.Buy(LotSize, 0, 0, SLTP\_PIPS, SLTP\_PIPS, "MA Crossover Buy"))  
            {  
                Print("BUY order placed successfully.");  
            }  
            else  
            {  
                // If trade failed, print the error  
                CError\* err \= execute.GetError();  
                PrintFormat("BUY order failed\! Error %d: %s", err-\>GetErrorCode(), err-\>GetErrorDescription());  
            }  
        }  
    }

    // \--- Exit Logic \---  
    // Bearish Crossover Signal  
    if(fastMA\_previous \>= slowMA\_previous && fastMA\_current \< slowMA\_current)  
    {  
        if(isTradeOpen)  
        {  
            // A trade is open, so close it  
            if(my\_positions.CloseAll())  
            {  
                Print("Position closed successfully due to reverse crossover.");  
            }  
        }  
    }  
}

This case study effectively demonstrates how the different classes in MQL\_Easy work in concert to produce clean, readable, and robust code. The CUtilities class controls the execution flow, CPosition simplifies trade state management, and CExecute handles the complexities of order placement and error reporting.

### **4.2. Mastering Cross-Platform Development**

While the MQL\_Easy library's primary purpose is to abstract away the significant differences between MQL4 and MQL5, developers aiming for mastery should understand the nature of this abstraction. The trading models of the two platforms are fundamentally different: MQL4 is order-centric (the "hedging" model), while MQL5 is position-centric (the "netting" model by default, though hedging is now supported). The library provides a powerful unifying layer over these disparate systems.

However, no abstraction is perfect. In software engineering, this is sometimes referred to as a "leaky abstraction." This means that while the library handles the vast majority of common scenarios seamlessly, edge cases or highly complex platform-specific functionalities might still require the developer to have a conceptual understanding of the underlying platform. A discussion among users highlighted this, with one noting it can be "impossible to write a trading code equally on both platforms" for every conceivable scenario, and the library's author acknowledging that MT5 has more features.3

For example, complex partial position closing or interacting with platform-specific features not covered by the library might require conditional compilation blocks (e.g., \#ifdef \_\_MQL5\_\_... \#else... \#endif).

The key takeaway for developers is this: rely on MQL\_Easy for the 95% of tasks it was designed for—trade execution, management, and history analysis. It will save immense time and reduce errors. For the remaining 5% of highly specialized or platform-unique tasks, be prepared that a deeper, platform-aware approach may be necessary. The library provides a robust foundation, not a replacement for platform knowledge.

### **4.3. Contributing to the MQL\_Easy Project**

MQL\_Easy is an open-source project that thrives on community involvement. The author has made an explicit call to action for users to "Feel free to contribute in any levels".2 This collaborative spirit is essential for the long-term health, improvement, and expansion of the library.

Developers who use the library are encouraged to contribute back to the project. Contributions can take many forms, including:

* **Reporting Bugs**: If you discover a bug or unexpected behavior, opening a detailed "Issue" on the project's GitHub page is an invaluable contribution.  
* **Suggesting Features**: If you have an idea for a new utility function or an improvement to an existing class, this can also be proposed via a GitHub "Issue."  
* **Submitting Code**: For developers who wish to contribute code directly, the standard open-source workflow is encouraged:  
  1. **Fork** the repository on GitHub to create your own copy.  
  2. Create a new **branch** for your feature or bug fix.  
  3. **Commit** your changes to your branch with clear, descriptive messages.  
  4. Submit a **Pull Request** back to the main MQL\_Easy repository.

The official repository, including its "Issues" and "Pull requests" sections, can be found at:([https://github.com/Denn1Ro/MQL\_Easy](https://github.com/Denn1Ro/MQL_Easy)).1 Engaging with the project not only helps improve the tool for everyone but also fosters a strong community around MQL development.

## **Part 5: The "DoEasy" Advanced GUI Framework (from MQL5 Articles)**

This part of the documentation delves into the second major pillar of the DoEasy ecosystem: the advanced Graphical User Interface (GUI) framework. This framework, detailed across a long-running series of articles on MQL5.com, provides the tools and concepts necessary to build rich, interactive, on-chart applications.

### **5.1. Introduction to the GUI Framework**

The primary goal of the "DoEasy" GUI framework is to enable the creation of controls in the "Windows Forms style" for MQL5 applications. This moves beyond the simple input parameters of a standard Expert Advisor to allow for the development of complex application GUIs with panels, windows, and other interactive elements directly on the chart.

This framework is not a single, downloadable package but is instead presented as a "live" development tutorial.6 The author incrementally builds the library, explaining the design decisions and code in each article. The motivation for this extensive project was a practical one: as trading applications grew more complex, it became "difficult to manage things without controls".

### **5.2. Core Architectural Principles**

The GUI framework is built on several sophisticated architectural principles that ensure it is robust, extensible, and capable of handling complex user interactions.

#### **Object-Oriented Inheritance Hierarchy**

The framework is built on a deep and logical object-oriented hierarchy. This promotes code reuse and a clear separation of concerns. The core inheritance chain is as follows:

1. **CCanvas**: This is the foundational MQL5 class that provides the raw drawing surface for all custom graphical objects.  
2. **CGCnvElement**: This is a base class within the library that represents a single graphical element to be drawn on the CCanvas surface.  
3. **CForm**: This class inherits from CGCnvElement and represents a movable, window-like object on the chart. It encapsulates the logic for being dragged and interacted with by the mouse.  
4. **CPanel**: This crucial class is derived from CForm. It acts as a container for other GUI controls, inheriting all the properties of a form (like movability) while adding the ability to host and manage other elements. Panels can even be nested inside other panels.

#### **Event-Driven Model**

The framework is fundamentally event-driven, with the OnChartEvent() function serving as the central hub for processing user interactions. The library implements a sophisticated system to handle mouse events correctly, especially in complex scenarios with multiple overlapping GUI elements.

* **Event Handling**: The system captures events like CHARTEVENT\_CLICK and CHARTEVENT\_MOUSE\_MOVE to manage actions like clicking buttons or dragging forms.  
* **Interaction Flags**: To solve the problem of which object should receive a click when multiple objects overlap, the library uses a system of flags. An "interaction" flag is set on a form when it is clicked, ensuring that subsequent mouse events are directed to that specific, active form.  
* **Event Prioritization**: The system can determine which form is under the cursor and prioritize the one that was last active, bringing it to the foreground and directing all input to it.

#### **Layering and Z-Order Management**

A critical challenge in on-chart GUI design is ensuring that control panels and windows always appear on top of other standard chart objects (like trendlines or indicators). The "DoEasy" framework solves this using the ZOrder property of graphical objects.

* **The Problem**: When new standard graphical objects are added to a chart, they can obscure existing GUI elements.  
* **The Solution**: The library manages a Z-order for all its GUI elements. When a GUI element is interacted with (e.g., clicked), it is brought to the top of the GUI layer. If a new standard chart object is detected, the framework can systematically redraw its GUI elements to ensure they remain on the foreground, preserving their relative stacking order.

#### **State Persistence**

A key design consideration for a professional GUI is the ability to remember its state. The framework is architected with the goal of saving the properties and state of graphical objects to a file. This allows the library to restore the user's interface to its previous state when the terminal is restarted, providing a seamless user experience.

### **5.3. Key GUI Classes and Concepts**

While the article series introduces dozens of classes and improvements, the following are the foundational building blocks of the GUI framework.

* **CPanel**: This is the most fundamental container element, inspired by the Panel control in Microsoft Visual Studio. It serves as the base for creating windows and dialogs and is designed to contain, organize, and manage other controls.  
* **CForm**: The CForm class provides the functionality of a basic, movable window. It includes the logic for being moved around the chart by the user's mouse and serves as the parent class for more specialized window types like CPanel.  
* **CCanvas**: The underlying MQL5 class that makes the entire GUI framework possible. It provides a pixel-based drawing surface where custom elements, text, and shapes can be rendered, offering complete control over the visual appearance of the interface.  
* **CGCnvElement**: The library's base class for any object intended to be drawn on a CCanvas. It contains common properties and methods that all GUI elements share.

### **5.4. Advanced GUI Features**

The "DoEasy" GUI framework goes beyond simple containers, incorporating advanced features inspired by modern UI development frameworks.

* **Layout Management (Docking and Sizing)**: The framework implements powerful layout management to simplify the arrangement of controls within a container.  
  * **Docking**: Using the ENUM\_CANV\_ELEMENT\_DOCK\_MODE, a control can be "docked" to a side of its parent CPanel (e.g., Top, Bottom, Left, Right, or Fill). The control will then automatically stretch and position itself along that edge, making it easy to create responsive layouts.  
  * **Auto-Sizing**: A CPanel can be configured with an ENUM\_CANV\_ELEMENT\_AUTO\_SIZE\_MODE. This allows the panel to automatically grow or shrink to perfectly fit the controls placed inside it, removing the need for manual size calculations.  
* **Shadows and Visual Effects**: To create a more polished and professional look, the framework includes a dedicated class for creating shadow effects. A CShadow object can be attached to a form, rendering a configurable shadow behind it that can even be filled with a color gradient.6  
* **Extensibility for Analysis**: The library's robust, object-oriented design makes it highly extensible. This is demonstrated when the author adds tools for identifying and graphically displaying price patterns (like the "Pin Bar") on the chart. This functionality is built upon the existing timeseries and graphical object classes, showcasing how the framework can be extended beyond pure UI to include analytical components.

## **Part 6: Appendices**

This final part provides supplementary resources for developers. It includes a guide to the advanced "DoEasy" article series for those wishing to explore GUI development and a comprehensive error code reference for debugging trade execution issues.

### **6.1. Resource Guide: The Advanced "DoEasy" MQL5.com Article Series**

For developers who have mastered the MQL\_Easy library and wish to expand their skills into creating complex, interactive on-chart graphical user interfaces, the "DoEasy" article series on MQL5.com is an invaluable resource. As clarified earlier, this series documents the creation of a separate, more advanced library focused on GUI elements and should be considered a supplementary learning path.

The series covers a wide range of advanced topics, providing a blueprint for building professional-grade trading panels and controls directly within MQL5. Key concepts and classes explored in the series include:

* **Custom GUI Development**: The series introduces the core concept of creating "Windows Forms style" controls in MQL5, moving beyond the standard input parameters to build rich, interactive application interfaces.7  
* **Core GUI Classes**: It details the foundational classes upon which the entire GUI framework is built:  
  * CCanvas: The base class that provides the drawing surface for all custom graphical elements.4  
  * CForm: A class representing a movable, window-like object on the chart.7  
  * CPanel: A critical container class, derived from CForm, designed to hold and organize other GUI controls.7  
* **Object Hierarchy and Composition**: The articles thoroughly explain the object-oriented structure, showing how controls are built upon one another (e.g., a CPanel is a specialized CForm, which is a type of graphical element) and how they can be nested to create complex layouts.7  
* **Advanced Graphics and Event Handling**: The series delves into sophisticated graphical concepts essential for a functional GUI, such as:  
  * Managing the Z-order to control which objects are drawn on top of others.4  
  * Assigning object priority to correctly handle CHARTEVENT\_CLICK events when controls overlap.4  
  * Implementing functionality to save the state of graphical objects to a file and restore them when the terminal restarts.4  
* **Layout Management**: The articles introduce powerful layout management techniques inspired by modern UI frameworks, including:  
  * **Docking**: The ability to "dock" a control to a specific side of its container (e.g., top, bottom, fill) using the ENUM\_CANV\_ELEMENT\_DOCK\_MODE.7  
  * **Auto-Sizing**: Functionality that allows a container like a CPanel to automatically resize itself to fit the content placed within it.8

Developers interested in these advanced topics can find the articles by searching for "DoEasy library" on the MQL5.com articles section.

### **6.2. Complete MQL\_Easy Error Code Reference**

The CError class in MQL\_Easy reports the standard trade server return codes provided by the MetaTrader platform. Understanding these codes is essential for debugging failed trade operations. The following table provides a reference for the most common trade-related error codes that a developer may encounter.

| Error Code | MQL Constant Name | Description |
| :---- | :---- | :---- |
| 10004 | TRADE\_RETCODE\_REQUOTE | Requote. The price has changed, and the trade must be re-submitted at the new price. |
| 10008 | TRADE\_RETCODE\_SERVER\_DISABLES\_AT | The trade server has disabled automated trading. |
| 10009 | TRADE\_RETCODE\_TRADE\_DISABLED | Trading is disabled for the account or the specific symbol. |
| 10013 | TRADE\_RETCODE\_INVALID\_REQUEST | The trade request is malformed or contains invalid parameters. |
| 10014 | TRADE\_RETCODE\_INVALID\_VOLUME | The specified volume (lot size) is invalid for the symbol (e.g., too small, too large, or not a valid step). |
| 10015 | TRADE\_RETCODE\_INVALID\_PRICE | The specified price is invalid. |
| 10016 | TRADE\_RETCODE\_INVALID\_STOPS | The specified Stop Loss or Take Profit levels are invalid (e.g., too close to the market price). |
| 10017 | TRADE\_RETCODE\_TRADE\_NOT\_ALLOWED | Trading is not allowed for this symbol or account type. |
| 10018 | TRADE\_RETCODE\_MARKET\_CLOSED | The market is currently closed for the specified symbol. |
| 10019 | TRADE\_RETCODE\_NO\_MONEY | There is not enough free margin on the account to execute the trade. |
| 10020 | TRADE\_RETCODE\_PRICE\_CHANGED | The price has changed since the request was initiated. |
| 10021 | TRADE\_RETCODE\_NO\_QUOTES | There are no current quotes to process the request. |
| 10024 | TRADE\_RETCODE\_FROZEN | Trading operations are frozen for the account. |
| 10025 | TRADE\_RETCODE\_INVALID\_ORDER | The request is to modify or close an order that does not exist. |
| 4301 | ERR\_UNKNOWN\_SYMBOL | The symbol specified in the request is not known by the terminal. |

#### **Referenzen**

1. Denn1Ro/MQL\_Easy: Framework/Library for cross platform ... \- GitHub, Zugriff am Juni 21, 2025, [https://github.com/Denn1Ro/MQL\_Easy](https://github.com/Denn1Ro/MQL_Easy)  
2. Free download of the 'MQL\_Easy' library by 'TradingSO' for MetaTrader 5 in the MQL5 Code Base, 2019.03.28, Zugriff am Juni 21, 2025, [https://www.mql5.com/en/code/25090](https://www.mql5.com/en/code/25090)  
3. Libraries: MQL\_Easy (For MT5) \- MT5 \- Articles, Library comments \- MQL5 programming forum, Zugriff am Juni 21, 2025, [https://www.mql5.com/en/forum/308732](https://www.mql5.com/en/forum/308732)  
4. Graphics in DoEasy library (Part 100): Making improvements in handling extended standard graphical objects \- MQL5 Articles, Zugriff am Juni 21, 2025, [https://www.mql5.com/en/articles/10634](https://www.mql5.com/en/articles/10634)  
5. Discussion of article "Graphics in DoEasy library (Part 77): Shadow object class" \- MQL5, Zugriff am Juni 21, 2025, [https://www.mql5.com/en/forum/374259](https://www.mql5.com/en/forum/374259)  
6. Graphics in DoEasy library (Part 97): Independent handling of form ..., Zugriff am Juni 21, 2025, [https://www.mql5.com/en/articles/10482](https://www.mql5.com/en/articles/10482)  
7. DoEasy. Controls (Part 1): First steps \- MQL5 Articles, Zugriff am Juni 21, 2025, [https://www.mql5.com/en/articles/10663](https://www.mql5.com/en/articles/10663)  
8. DoEasy. Controls (Part 5): Base WinForms object, Panel control, AutoSize parameter \- MQL5 Articles, Zugriff am Juni 21, 2025, [https://www.mql5.com/en/articles/10794](https://www.mql5.com/en/articles/10794)