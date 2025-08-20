from pywinauto import Application
from pywinauto import mouse, keyboard
import pythoncom



def LPWAD(float_number):
    pythoncom.CoInitializeEx(pythoncom.COINIT_APARTMENTTHREADED)
    float_number = round(float_number, 2)

    app = Application().connect(title="OPSL 3.7") 
    window = app.window(title="OPSL 3.7")

    window.restore()
    window.set_focus()
    rect = window.rectangle()


    offset_x = 147 
    offset_y =237
    click_x = rect.left + offset_x
    click_y = rect.top + offset_y


    window.wait('visible', timeout=10)
    try:
        mouse.double_click(coords=(click_x, click_y))
    except Exception as e:
        print(f"faliure {e}")


    offset_x = 190 
    offset_y = 120 

    click_x = rect.left + offset_x
    click_y = rect.top + offset_y


    window.wait('visible', timeout=10)

    try:
        mouse.double_click(coords=(click_x, click_y))

        for _ in range(5):
            keyboard.send_keys('{BACKSPACE}')
        
        keyboard.send_keys(f'{float_number:.2f}')

        keyboard.send_keys('{ENTER}')

    except Exception as e:
        print(f"faliure {e}")