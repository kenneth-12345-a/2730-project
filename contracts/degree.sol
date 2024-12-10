// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UserRecords is ERC721URIStorage, Ownable {
    enum NFTType { Degree, WorkExperience }

    struct Degree {
        string studentName;
        string studentID;
        string universityName;
        string degreeName;
        string major;
        string issueDate;
    }

    struct WorkExperience {
        string userName;
        string companyName;
        string role;
        string startDate;
        string endDate;
        string employerComments;
    }

    struct UserProfile {
        string name;
        string skills;
        string strengths;
        string selfIntroduction;
        string additionalInfo;
    }

    struct NFTMetadata {
        NFTType nftType;
        uint256 tokenId;
    }

    mapping(uint256 => Degree) private degrees; // Mapping token ID to Degree details
    mapping(uint256 => WorkExperience) private workExperiences; // Mapping token ID to Work Experience details
    mapping(address => string) private authorizedUniversities; // Authorized universities
    mapping(address => string) private authorizedEmployers; // Authorized employers
    mapping(address => NFTMetadata[]) private userNFTs; // Mapping of user addresses to their NFTs
    mapping(address => UserProfile) private userProfiles; // Mapping of user addresses to their profiles

    uint256 private nextTokenId; // Counter for unique token IDs

    event DegreeIssued(
        uint256 indexed tokenId,
        address indexed student,
        address indexed university,
        string degreeName
    );

    event WorkExperienceIssued(
        uint256 indexed tokenId,
        address indexed user,
        address indexed employer,
        string companyName,
        string role
    );

    event ProfileUpdated(
        address indexed user,
        string name,
        string skills,
        string strengths,
        string selfIntroduction,
        string additionalInfo
    );

    constructor() ERC721("UserRecordsNFT", "URNFT") Ownable(msg.sender) {
        nextTokenId = 1; // Start token IDs from 1
    }

    // Modifier to restrict actions to authorized universities
    modifier onlyAuthorizedUniversity() {
        require(
            bytes(authorizedUniversities[msg.sender]).length > 0,
            "You are not an authorized university"
        );
        _;
    }

    // Modifier to restrict actions to authorized employers
    modifier onlyAuthorizedEmployer() {
        require(
            bytes(authorizedEmployers[msg.sender]).length > 0,
            "You are not an authorized employer"
        );
        _;
    }

    

    // Function to authorize a university
    function authorizeUniversity(address university, string memory name) external onlyOwner {
        authorizedUniversities[university] = name;
    }
    // Function to authorize an employer               
    function authorizeEmployer(address employer, string memory name) external onlyOwner {
        authorizedEmployers[employer] = name;
    }
    
    // Function to revoke university authorization
    function revokeUniversity(address university) external onlyOwner {
        delete authorizedUniversities[university];
    }
    // Function to revoke employer authorization
    function revokeEmployer(address employer) external onlyOwner {
        delete authorizedEmployers[employer];
    }

    // Function to issue a degree NFT
    function issueDegree(
        address student,
        string memory studentName,
        string memory studentID,
        string memory degreeName,
        string memory major,
        string memory issueDate
    ) external onlyAuthorizedUniversity {
        require(student != address(0), "Invalid student address");

        uint256 tokenId = nextTokenId;
        nextTokenId++;

        // Store degree details
        degrees[tokenId] = Degree({
            studentName: studentName,
            studentID: studentID,
            universityName: authorizedUniversities[msg.sender],
            degreeName: degreeName,
            major: major,
            issueDate: issueDate
        });

        // Mint NFT and track it
        _safeMint(student, tokenId);
        userNFTs[student].push(NFTMetadata(NFTType.Degree, tokenId));

        emit DegreeIssued(tokenId, student, msg.sender, degreeName);
    }

    // Function to issue a work experience NFT
    function issueWorkExperience(
        address user,
        string memory userName,
        string memory role,
        string memory startDate,
        string memory endDate,
        string memory employerComments
    ) external onlyAuthorizedEmployer {
        require(user != address(0), "Invalid user address");

        uint256 tokenId = nextTokenId;
        nextTokenId++;

        // Store work experience details
        workExperiences[tokenId] = WorkExperience({
            userName: userName,
            companyName: authorizedEmployers[msg.sender],
            role: role,
            startDate: startDate,
            endDate: endDate,
            employerComments: employerComments
        });

        // Mint NFT and track it
        _safeMint(user, tokenId);
        userNFTs[user].push(NFTMetadata(NFTType.WorkExperience, tokenId));

        emit WorkExperienceIssued(tokenId, user, msg.sender, authorizedEmployers[msg.sender], role);
    }

    // Function to update user profile
    function updateProfile(
        string memory name,
        string memory skills,
        string memory strengths,
        string memory selfIntroduction,
        string memory additionalInfo
    ) external {
        userProfiles[msg.sender] = UserProfile({
            name: name,
            skills: skills,
            strengths: strengths,
            selfIntroduction: selfIntroduction,
            additionalInfo: additionalInfo
        });

        emit ProfileUpdated(msg.sender, name, skills, strengths, selfIntroduction, additionalInfo);
    }

    function getUserProfileAndNFTs(address user)
    external
    view
    returns (UserProfile memory profile, Degree[] memory degreesOwned, WorkExperience[] memory experiencesOwned)
    {
        profile = userProfiles[user];
        NFTMetadata[] memory nfts = userNFTs[user];
    
        uint8 degreeCount = 0;
        uint8 experienceCount = 0;

        // First pass: Count degrees and work experiences to initialize arrays
        for (uint256 i = 0; i < nfts.length; i++) {
            if (nfts[i].nftType == NFTType.Degree) {
                degreeCount++;
            } else if (nfts[i].nftType == NFTType.WorkExperience) {
                experienceCount++;
            }
        }

        // Initialize memory arrays with correct sizes
        degreesOwned = new Degree[](degreeCount);
        experiencesOwned = new WorkExperience[](experienceCount);

        // Second pass: Populate the arrays
        uint8 degreeIndex = 0;
        uint8 experienceIndex = 0;
        for (uint256 i = 0; i < nfts.length; i++) {
            if (nfts[i].nftType == NFTType.Degree) {
                degreesOwned[degreeIndex] = degrees[nfts[i].tokenId]; // Access mapping directly
                degreeIndex++;
            } else if (nfts[i].nftType == NFTType.WorkExperience) {
                experiencesOwned[experienceIndex] = workExperiences[nfts[i].tokenId]; // Access mapping directly
                experienceIndex++;
            }
        }
    }


    // Function to retrieve degree details by token ID
    function getDegree(uint256 tokenId)
        external
        view
        returns (Degree memory)
    {
        require(bytes(degrees[tokenId].studentName).length > 0, "Degree does not exist");
        return degrees[tokenId];
    }

    // Function to retrieve work experience details by token ID

    function getWorkExperience(uint256 tokenId)
        external
        view
        returns (WorkExperience memory)
    {
        require(bytes(workExperiences[tokenId].userName).length > 0, "Work experience does not exist");
        return workExperiences[tokenId];
    }

    // Function to check if a university is authorized
    function isAuthorizedUniversity(address university)
        external
        view
        returns (bool)
    {
        return bytes(authorizedUniversities[university]).length > 0;
    }

    // Function to check if an employer is authorized
    function isAuthorizedEmployer(address employer)
        external
        view
        returns (bool)
    {
        return bytes(authorizedEmployers[employer]).length > 0;
    }

}
