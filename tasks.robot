*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF

*** Variables ***
${URL} =    https://robotsparebinindustries.com/#/robot-order
${GLOBAL_RETRY_COUNT} =    5x
${GLOBAL_RETRY_INTERVAL} =    1s

*** Keywords ***
Open the robot order website
    Open Available Browser    ${URL}

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=    Read table from CSV    ${CURDIR}${/}orders.csv
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

Store the receipt as a PDF file 
    [Arguments]    ${order number}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML

    ${pdf_path}=    Set Variable    ${OUTPUT_DIR}${/}receipts${/}receipt-${order number}.pdf
    Html To Pdf    ${receipt_html}    ${pdf_path}
    [Return]    ${pdf_path}

Take a screenshot of the robot
    [Arguments]    ${order number}
    Wait Until Element Is Visible    id:robot-preview-image
    Sleep    0.5s 
    ${screenshot_path}=    Set Variable    ${OUTPUT_DIR}${/}screenshots${/}screenshot-${order number}.png
    Screenshot    id:robot-preview-image    ${screenshot_path}
    [Return]    ${screenshot_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot_path}    ${pdf_path}
    ${screenshot_list}=    Create List    ${screenshot_path}
    Add Files To Pdf    ${screenshot_list}    ${pdf_path}    append=True


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
        ${pdf_path}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot_path}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot_path}    ${pdf_path}
        Order another robot
    END
    # Create a ZIP file of the receipts
