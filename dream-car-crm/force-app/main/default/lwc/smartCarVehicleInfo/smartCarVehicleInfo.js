import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getVehicleInfo from '@salesforce/apex/SmartCarService.getVehicleInfo';
import getVehicleLocation from '@salesforce/apex/SmartCarService.getVehicleLocation';

export default class SmartCarVehicleInfo extends LightningElement {

    @api vehicleId;
    @api scUserId;

    make;
    model;
    year;
    powertrainType;

    latitude;
    longitude;

    isLoading = false;
    errorMessage;

    hasVehicleInfo = false;
    hasLocation = false;

    connectedCallback() {
        if (this.vehicleId && this.scUserId) {
            this.fetchVehicleInfo();
        }
    }

    handleVehicleIdChange(event) {
        this.vehicleId = event.target.value;
        this.hasVehicleInfo = false;
        this.hasLocation = false;
        this.errorMessage = undefined;
    }

    handleScUserIdChange(event) {
        this.scUserId = event.target.value;
    }

    handleFetchInfoClick() {
        this.fetchVehicleInfo();
    }

    handleFetchLocationClick() {
        this.fetchVehicleLocation();
    }

    async fetchVehicleInfo() {
        if (!this.validateInputs()) {
            return;
        }

        this.isLoading = true;
        this.errorMessage = undefined;

        try {
            const result = await getVehicleInfo({ vehicleId: this.vehicleId, scUserId: this.scUserId });

            if (result.isSuccess) {
                this.make = result.make;
                this.model = result.model;
                this.year = result.year;
                this.powertrainType = result.powertrainType;
                this.hasVehicleInfo = true;
            } else {
                this.hasVehicleInfo = false;
                this.setError(result.errorMessage);
            }
        } catch (error) {
            this.hasVehicleInfo = false;
            this.setError(this.extractErrorMessage(error));
        } finally {
            this.isLoading = false;
        }
    }

    async fetchVehicleLocation() {
        if (!this.validateInputs()) {
            return;
        }

        this.isLoading = true;
        this.errorMessage = undefined;

        try {
            const result = await getVehicleLocation({ vehicleId: this.vehicleId, scUserId: this.scUserId });

            if (result.isSuccess) {
                this.latitude = result.latitude;
                this.longitude = result.longitude;
                this.hasLocation = true;
            } else {
                this.hasLocation = false;
                this.setError(result.errorMessage);
            }
        } catch (error) {
            this.hasLocation = false;
            this.setError(this.extractErrorMessage(error));
        } finally {
            this.isLoading = false;
        }
    }

    validateInputs() {
        if (!this.vehicleId) {
            this.setError('Please enter a Vehicle Id before fetching data.');
            return false;
        }

        if (!this.scUserId) {
            this.setError('Please enter a SmartCar User Id before fetching data.');
            return false;
        }

        return true;
    }

    setError(message) {
        this.errorMessage = message || 'An unexpected error occurred. Please try again.';

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'SmartCar Error',
                message: this.errorMessage,
                variant: 'error'
            })
        );
    }

    extractErrorMessage(error) {
        if (error && error.body && error.body.message) {
            return error.body.message;
        }

        if (error && error.message) {
            return error.message;
        }

        return 'An unexpected error occurred. Please try again.';
    }

    get locationDisplay() {
        if (this.hasLocation && this.latitude != null && this.longitude != null) {
            return `${this.latitude}, ${this.longitude}`;
        }

        return 'Not available';
    }

    get isFetchDisabled() {
        return this.isLoading || !this.vehicleId || !this.scUserId;
    }
}