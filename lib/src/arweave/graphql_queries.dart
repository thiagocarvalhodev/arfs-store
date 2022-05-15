const queryFolder = r"""
query DriveEntityHistory($folderId: String!, $lastBlockHeight: Int) {
  transactions(
    first: 1
    sort: HEIGHT_ASC
    tags: [
      { name: "ArFS", values: ["0.10", "0.11"] }
      { name: "Folder-Id", values: [$folderId] }
    ]
    block: {min: $lastBlockHeight}
  ) {
    edges {
      node {
        id
        owner {
          address
        }
        bundledIn {
          id
        }
        block {
          height
        }
        tags {
          name
          value
        }
      }
      cursor
    }
  }
}

""";

const queryEntity = r"""

query DriveEntityHistory($driveId: String!, $lastBlockHeight: Int, $tag: String!) {
  transactions(
    first: 100
    sort: HEIGHT_ASC
    tags: [
      { name: "ArFS", values: ["0.10", "0.11"] }
      { name: $tag, values: [$driveId] }
      { name: "Entity-Type", values: ["folder", "file"] }
    ]
    block: {min: $lastBlockHeight}
  ) {
    edges {
      node {
        id
        owner {
          address
        }
        bundledIn {
          id
        }
        block {
          height
        }
        tags {
          name
          value
        }
      }
      cursor
    }
  }
}

""";

const getRootFolderQuery = r"""
query getAllDrivesFromUser($folderId: String!) {
   transactions(
     block: {min: 0}
     first: 100
     tags: [
       { name: "ArFS", values: "0.11" }
       { name: "Entity-Type", values: ["folder", "file"] }
       { name: "Parent-Folder-Id", values: [$folderId]}
      ]
    ) {
      edges {
        node {
          id
          tags {
            name
            value
          }
        }
      }
    }
  }
""";

const getPublicDrives = r"""
query getPublicDrives($owner: String!) {
   transactions(
     block: {min: 0}
     first: 100
     owners: [$owner]
     tags: [
       { name: "ArFS", values: "0.11" }
       { name: "Entity-Type", values: "drive" }
       { name: "Drive-Privacy", values: "public" }
      ]
    ) {
      edges {
        node {
          id
          tags {
            name
            value
          }
        }
      }
    }
  }
""";
