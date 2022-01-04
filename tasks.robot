*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.Tables

*** Variables ***
${URL} =    https://robotsparebinindustries.com/#/robot-order
${GLOBAL_RETRY_COUNT} =    3x
${GLOBAL_RETRY_INTERVAL} =    1s

*** Keywords ***
Open the robot order website
    Open Available Browser    ${URL}

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=    Read table from CSV    ${CURDIR}/orders.csv
    [Return]    ${orders} 
    
Close the annoying modal
    Click Button When Visible    css:.btn-dark

Fill the form
    [Arguments]    ${order}
    Select From List By Value   id:head     ${order}[Head]
    Select Radio Button    body     ${order}[Body]  

    # todo: could be more robust
    Input Text    xpath: //input[@placeholder='Enter the part number for the legs']     ${order}[Legs]
    Input Text    id:address    text=${order}[Address]

Preview the robot
    Click Button    id:preview
    Assert preview generated

Assert preview generated
    Wait Until Page Contains Element    id:robot-preview-image

Submit the order
    Click Button    id:order
    Assert order completed

Assert order completed
    # Sleep    ${Global_Retry_Interval}
    Wait Until Page Contains Element    id:receipt

Order another robot
    Click Button    id:order-another

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    # Close the annoying modal
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}

        Wait Until Keyword Succeeds    ${GLOBAL_RETRY_COUNT}    ${GLOBAL_RETRY_INTERVAL}    Preview the robot
        
        Wait Until Keyword Succeeds    ${GLOBAL_RETRY_COUNT}    ${GLOBAL_RETRY_INTERVAL}    Submit the order
    #     ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
    #     ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
    #     Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Order another robot
    END
    # Create a ZIP file of the receipts
