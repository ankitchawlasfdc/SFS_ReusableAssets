import { LightningElement } from 'lwc';
import LOCALE from "@salesforce/i18n/locale";

export default class Formatted_Date extends LightningElement {
    dateTimeValue;

    connectedCallback() {
        this.getCurrentTime();
    }

    getCurrentTime() {
        this.dateTimeValue = new Intl.DateTimeFormat(LOCALE).format(new Date());
    }
}